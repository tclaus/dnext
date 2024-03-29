# frozen_string_literal: true

module SessionsHelper
  def prefilled_username
    uri = Addressable::URI.parse(session["user_return_to"])
    uri.query_values["login_hint"] if uri&.query_values
  end

  def authorization_context?
    uri = Addressable::URI.parse(session["user_return_to"])
    client_id = session["client_id"]
    uri && uri.path.match("openid_connect").present? || client_id.present?
  end

  def open_id_context?
    uri = Addressable::URI.parse(session["user_return_to"])
    client_id = session["client_id"]
    if uri && uri.path.match("openid_connect").present? || client_id.present?
      true
    else
      false
    end
  end

  def display_registration_link?
    AppConfig.settings.enable_registrations? && controller_name != "registrations"
  end

  def display_password_reset_link?
    AppConfig.mail.enable? && devise_mapping.recoverable? && controller_name != "passwords"
  end

  def flash_class(name)
    { notice: "success", alert: "danger", error: "danger" }[name.to_sym]
  end
end
