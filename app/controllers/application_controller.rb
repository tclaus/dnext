# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  protect_from_forgery except: :receive, with: :exception, prepend: true
  layout "with_header_with_footer"

  rescue_from ActionController::InvalidAuthenticityToken do
    if user_signed_in?
      logger.warn "#{current_user.diaspora_handle} CSRF token fail. referer: #{request.referer || "empty"}"
      Workers::Mail::CsrfTokenFail.perform_async(current_user.id)
      sign_out current_user
    end
    flash[:error] = I18n.t("error_messages.csrf_token_fail")
    redirect_to new_user_session_path format: request[:format]
  end

  def set_diaspora_header
    headers["X-Diaspora-Version"] = AppConfig.version_string

    if AppConfig.git_available?
      headers["X-Git-Update"] = AppConfig.git_update if AppConfig.git_update.present?
      headers["X-Git-Revision"] = AppConfig.git_revision if AppConfig.git_revision.present?
    end
  end

  def redirect_unless_admin
    return if current_user.admin?
    redirect_to stream_url, notice: "you need to be an admin to do that"
  end

  def redirect_unless_moderator
    return if current_user.moderator?
    redirect_to stream_url, notice: "you need to be an admin or moderator to do that"
  end

  def after_sign_in_path_for(resource)
    stored_location_for(:user) || current_user_redirect_path
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def current_user_redirect_path
    # If getting started is active AND the users has not completed the getting_started page
    if current_user.getting_started? && !current_user.basic_profile_present?
      getting_started_path
    else
      stream_path
    end
  end

  protected

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end
end
