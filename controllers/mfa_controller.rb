class MfaController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:send_otp, :verify_otp, :verify_guid]

  def send_otp
    phone_number = normalize_phone_number(params[:phone_number])
    Rails.logger.info "send_otp: Received phone number: '#{phone_number}'"
    user = User.find_by(phone_number: phone_number)
    
    if user
      otp = rand(100000..999999) # Generate a 6-digit OTP
      user.update(otp_code: otp, otp_expires_at: 10.minutes.from_now)
      Rails.logger.info "send_otp: Generated OTP #{otp} for #{user.phone_number}"
      
      send_sms(user.phone_number, "Your OTP is: #{otp}")
      render json: { message: "OTP sent to #{user.phone_number}" }
    else
      Rails.logger.warn "send_otp: User with phone number '#{phone_number}' not found."
      render json: { error: "Phone number not found" }, status: :not_found
    end
  end

  def verify_guid
    phone_number = normalize_phone_number(params[:phone_number])
    Rails.logger.info "verify_guid: Received phone number: '#{phone_number}'"
    user = User.find_by(phone_number: phone_number)
    
    if request.get?
      @phone_number = phone_number
      render 'verify_guid'  # Expects app/views/mfa/verify_guid.html.erb
    elsif request.post?
      provided_guid = params[:guid].to_s.strip
      if user && user.handle.to_s.strip == provided_guid
        otp = rand(100000..999999)
        user.update(otp_code: otp, otp_expires_at: 10.minutes.from_now)
        Rails.logger.info "verify_guid: GUID verified; generated OTP #{otp} for #{user.phone_number}"
        send_sms(user.phone_number, "Your OTP is: #{otp}")
        flash[:notice] = "OTP sent to #{user.phone_number}"
        redirect_to new_otp_verification_path(phone_number: user.phone_number)
      else
        flash.now[:alert] = "Invalid GUID. Please try again."
        @phone_number = phone_number
        render 'verify_guid'
      end
    end
  end

  def verify_otp
    if request.get?
      @phone_number = normalize_phone_number(params[:phone_number])
      render 'verify_otp'  # Expects app/views/mfa/verify_otp.html.erb
    elsif request.post?
      phone_number = normalize_phone_number(params[:phone_number])
      otp_entered = params[:otp].to_s.strip
      user = User.find_by(phone_number: phone_number)
      
      if user && user.otp_code.to_s == otp_entered && Time.current < user.otp_expires_at
        user.update(otp_code: nil, otp_expires_at: nil)
        user.devices.create(device_info: request.user_agent)
        sign_in(user)
        redirect_to root_path, notice: "Device verified! Logged in successfully."
      else
        flash[:alert] = "Invalid or expired OTP"
        redirect_to new_user_session_path
      end
    end
  end

  private

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

  def normalize_phone_number(number)
    number = number.to_s.strip
    number.start_with?('+') ? number : "+#{number}"
  end
end
