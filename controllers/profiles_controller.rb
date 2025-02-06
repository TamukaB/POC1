class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    new_handle = profile_params[:handle].to_s.strip

    if new_handle.present? && new_handle != @user.handle
      session[:new_handle] = new_handle

      otp = rand(100000..999999)
      @user.update(otp_code: otp, otp_expires_at: 10.minutes.from_now)
      Rails.logger.info "update: Generated OTP #{otp} for GUID update for #{@user.phone_number}"

      send_sms(@user.phone_number, "Your OTP for updating your GUID is: #{otp}")

      redirect_to confirm_update_profile_path, notice: "An OTP has been sent to your phone. Please confirm to update your GUID."
    else
      redirect_to profile_path, notice: "No changes made."
    end
  end

  def confirm_update
  end

  def confirm_update_process
    @user = current_user
    if @user.otp_code.to_s == params[:otp].to_s.strip && Time.current < @user.otp_expires_at
      new_handle = session.delete(:new_handle)
      @user.update(handle: new_handle, otp_code: nil, otp_expires_at: nil)
      redirect_to profile_path, notice: "GUID updated successfully."
    else
      flash.now[:alert] = "Invalid or expired OTP. Please try again."
      render :confirm_update
    end
  end

  def confirm_delete
  end

  def destroy
    @user = current_user
    provided_guid = params[:guid].to_s.strip 

    if @user.handle.to_s.strip == provided_guid
      Rails.logger.info "Destroying user: #{@user.id} - #{@user.handle}"
      @user.destroy
      reset_session

      flash[:notice] = "Your account has been permanently deleted"
      redirect_to new_user_registration_path
    else
      flash[:alert] = "Incorrect GUID. Account deletion failed."
      redirect_to confirm_delete_profile_path
    end
  end

  private

  def profile_params
    params.require(:user).permit(:handle)
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
