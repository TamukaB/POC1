class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  # Override the create action to generate an OTP and redirect to OTP verification
  def create
    build_resource(sign_up_params)
    
    resource.phone_number = normalize_phone_number(sign_up_params[:phone_number])
    resource.handle = sign_up_params[:handle].to_s.strip
    # Set a dummy password, since we use phone-based auth.
    resource.password = SecureRandom.hex(10) if resource.password.blank?

    resource.save
    yield resource if block_given?
    if resource.persisted?
      # Generate OTP for initial device registration
      otp = rand(100000..999999)
      resource.update(otp_code: otp, otp_expires_at: 10.minutes.from_now)
      send_sms(resource.phone_number, "Your OTP is: #{otp}")

      # Do not sign in automatically; redirect to OTP verification page.
      redirect_to new_otp_verification_path(phone_number: resource.phone_number), 
                  notice: "An OTP has been sent to your phone. Please verify your account."
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:phone_number, :handle])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:phone_number, :handle])
  end

  def build_resource(hash = {})
    hash[:email] = "#{hash[:phone_number]}@example.com" if hash[:email].blank?
    hash[:password] = SecureRandom.hex(10) if hash[:password].blank?
    super
  end

  def set_minimum_password_length
    @minimum_password_length = 0
  end

  private

  def normalize_phone_number(number)
    number = number.to_s.strip
    number.start_with?('+') ? number : "+#{number}"
  end

  def send_sms(to, message)
    client = Twilio::REST::Client.new(ENV["TWILIO_ACCOUNT_SID"], ENV["TWILIO_AUTH_TOKEN"])
    begin
      response = client.messages.create(
        from: ENV["TWILIO_PHONE_NUMBER"],
        to: to,
        body: message
      )
      Rails.logger.info "send_sms: SMS sent successfully. Message SID: #{response.sid}"
    rescue Twilio::REST::RestError => e
      Rails.logger.error "send_sms: Failed to send SMS: #{e.message}"
    end
  end
end
