class User < ApplicationRecord
  has_many :devices, dependent: :destroy
  devise :registerable, :database_authenticatable, :validatable
  
  after_commit :replicate_database, on: :create  # ✅ Ensures replication happens after full save
  after_destroy :delete_replicated_db  
  before_update :mark_as_unsynced_if_offline
  
  validates :phone_number, presence: true, uniqueness: true
  validates :handle, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z0-9_]+\z/, message: "can only contain letters, numbers, and underscores" }

  before_validation :set_dummy_email_and_password

  scope :unsynced, -> { where(synced: false) }

  def mark_as_synced
    update(synced: true, last_synced_at: Time.current)
  end 

  def mark_as_unsynced_if_offline
    if self.synced && some_condition_to_check_if_user_is_offline
      self.synced = false
    end
  end

  def replicate_database
    return unless persisted?  # ✅ Ensure user is fully saved before replication

    original_db_path = Rails.root.join("storage", "#{Rails.env}.sqlite3")

    unless File.exist?(original_db_path)
      Rails.logger.error "❌ Original DB not found at #{original_db_path} for user #{id}"
      return false
    end 

    destination_dir = "/var/www/POC1/replicated_dbs/#{handle}"
    FileUtils.mkdir_p(destination_dir) unless Dir.exist?(destination_dir)

    destination_db_path = File.join(destination_dir, "database.sqlite3")

    begin
      FileUtils.cp(original_db_path, destination_db_path)
      Rails.logger.info "✅ Database replicated for user #{id} (GUID: #{handle})"

      update_column(:replicated_db_path, destination_db_path)  

      return true
    rescue StandardError => e
      Rails.logger.error "❌ Failed to replicate DB for user #{id}: #{e.message}"
      return false
    end 
  end 

  def delete_replicated_db
    Rails.logger.info "🛑 Attempting to delete replicated DB for user #{id} (#{handle})..."

    if replicated_db_path.present? && File.exist?(replicated_db_path)
      File.delete(replicated_db_path)
      Rails.logger.info "✅ Deleted replicated database for user #{id} at #{replicated_db_path}"
    else
      Rails.logger.warn "⚠️ Replicated database file not found for user #{id}, skipping deletion."
    end

    user_directory = File.dirname(replicated_db_path) rescue nil
    if user_directory && Dir.exist?(user_directory) && Dir.empty?(user_directory)
      Dir.rmdir(user_directory)
      Rails.logger.info "✅ Deleted empty user directory: #{user_directory}"
    else
      Rails.logger.warn "⚠️ User directory not empty or doesn't exist: #{user_directory}"
    end
  end

  private

  def set_dummy_email_and_password
    self.email = "#{phone_number}@example.com" if email.blank?
    self.password ||= SecureRandom.hex(10) if encrypted_password.blank?
  end

  def some_condition_to_check_if_user_is_offline
    return true unless last_synced_at

    Time.current - last_synced_at > 24.hours
  end
end
