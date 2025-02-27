class Users::SessionsController < Devise::SessionsController
  before_action :check_user_signed_in, only: [:new]

  def new
    super
  end

  def create
    user = User.find_by(phone_number: params[:user][:phone_number])
    
    if user
      device_info = request.user_agent
      existing_device = user.devices.find_by(device_info: device_info)

      if existing_device
        sign_in(user)
        flash[:notice] = "Welcome back, #{user.handle}! You have successfully signed in."
        redirect_to root_path
      else
        # New device detected: redirect to GUID verification step
        flash[:alert] = "New device detected. Please verify your GUID."
        redirect_to new_guid_verification_path(phone_number: user.phone_number)
      end
    else
      flash[:alert] = "Phone number not found"
      redirect_to new_user_session_path
    end
  end

  def destroy
    super do
      flash[:notice] = "You have been logged out successfully. See you again soon!"
    end
  end

  protected

  def after_sign_in_path_for(resource)
    root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  private

  def check_user_signed_in
    redirect_to root_path if user_signed_in?
  end
end
