# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  def find_user
    return User.find_for_authentication(username: params[:user][:username]) if params[:user][:username]

    User.find(session[:otp_user_id]) if session[:otp_user_id]
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:username, :password, :otp_attempt])
  end
end
