# frozen_string_literal: true

class ApplicationController < ActionController::Base
  around_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?
  protect_from_forgery except: :receive, with: :exception, prepend: true
  layout "with_header_with_footer"

  helper_method :countless_stream_next_tag

  rescue_from ActionController::InvalidAuthenticityToken do
    if user_signed_in?
      logger.warn "#{current_user.diaspora_handle} CSRF token fail. referer: #{request.referer || 'empty'}"
      CsrfTokenFail.perform_later(current_user.id)
      sign_out current_user
    end
    flash[:error] = I18n.t("error_messages.csrf_token_fail")
    redirect_to new_user_session_path format: request[:format]
  end

  def set_diaspora_header
    headers["X-Diaspora-Version"] = AppConfig.version_string

    return unless AppConfig.git_available?

    headers["X-Git-Update"] = AppConfig.git_update if AppConfig.git_update.present?
    headers["X-Git-Revision"] = AppConfig.git_revision if AppConfig.git_revision.present?
  end

  def set_locale(&action)
    if user_signed_in?
      locale = current_user.try(:language) || I18n.default_locale
      locale = DEFAULT_LANGUAGE unless AVAILABLE_LANGUAGE_CODES.include?(locale)
    else
      locale = http_accept_language.language_region_compatible_from AVAILABLE_LANGUAGE_CODES
      locale ||= DEFAULT_LANGUAGE
    end
    I18n.with_locale(locale, &action)
  end

  def redirect_unless_admin
    return if current_user.admin?

    redirect_to stream_url, notice: "you need to be an admin to do that"
  end

  def redirect_unless_moderator
    return if current_user.moderator?

    redirect_to stream_url, notice: "you need to be an admin or moderator to do that"
  end

  def after_sign_in_path_for(_resource)
    stored_location_for(:user) || current_user_redirect_path
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(_resource_or_scope)
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

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end

  # This method helps to mark the end of a paginated endless stream of data
  # @param [Pagy] pagy
  # @return [String] A html tag with a next marker
  def countless_stream_next_tag(pagy)
    "<a href='#{request.path}?#{pagy.vars[:page_param]}=#{pagy.vars[:page].to_i + 1}' rel='next'>Next</a>"
      .html_safe # rubocop:disable Rails/OutputSafety
  end
end
