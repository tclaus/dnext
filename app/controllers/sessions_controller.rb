# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authenticate_with_2fa, only: :create
  # rubocop:enable Rails/LexicallyScopedActionFilter

  def find_user
    return User.find_for_authentication(username: params[:user][:username]) if params[:user][:username]

    User.find(session[:otp_user_id]) if session[:otp_user_id]
  end

  def authenticate_with_2fa
    self.resource = find_user

    return true unless resource&.otp_required_for_login?

    if params[:user][:otp_attempt].present? && session[:otp_user_id]
      authenticate_with_2fa_via_otp(resource)
    else
      strategy = Warden::Strategies[:database_authenticatable].new(warden.env, :user)
      prompt_for_two_factor(strategy.user) if strategy.valid? && strategy._run!.successful?
    end
  end

  def authenticate_with_2fa_via_otp(user)
    if valid_otp_attempt?(user)
      session.delete(:otp_user_id)
      sign_in(user)
    else
      flash.now[:alert] = t("two_factor_auth..invalid_token")
      prompt_for_two_factor(user)
    end
  end

  def valid_otp_attempt?(user)
    user.validate_and_consume_otp!(params[:user][:otp_attempt]) ||
      user.invalidate_otp_backup_code!(params[:user][:otp_attempt])
  rescue OpenSSL::Cipher::CipherError => _e
    false
  end

  def prompt_for_two_factor(user)
    session[:otp_user_id] = user.id
    render :two_factor
  end
end
