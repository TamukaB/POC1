class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_devise_mapping

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:phone_number, :handle])
    devise_parameter_sanitizer.permit(:account_update, keys: [:phone_number, :handle])
  end

  def set_devise_mapping
    request.env["devise.mapping"] = Devise.mappings[:user]
  end
end
