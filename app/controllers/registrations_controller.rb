# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  invisible_captcha only: %i[create update], honeypot: :subtitle
  before_action :check_registrations_open_or_valid_invite!, except: :registrations_closed
  layout "with_header_with_footer"

  def create
    @user = User.build(user_params)

    if @user.sign_up
      flash[:notice] = t("registrations.create.success")
      @user.seed_aspects
      @user.send_welcome_message
      sign_in_and_redirect(:user, @user)
      logger.info "event=registration status=successful users=#{@user.diaspora_handle}"
    else
      @user.errors.delete(:person)

      flash.now[:error] = @user.errors.full_messages.join(" - ")
      logger.info "event=registration status=failure errors='#{@user.errors.full_messages.join(', ')}'"
      render action: "new"
    end
  end

  def registrations_closed
    render "registrations/registrations_closed"
  end

  private

  def check_registrations_open_or_valid_invite!
    return true if AppConfig.settings.enable_registrations? || invite.try(:can_be_used?)

    flash[:error] = t("registrations.invalid_invite") if params[:invite]
    redirect_to registrations_closed_path
  end

  def invite
    @invite ||= InvitationCode.find_by_token(params[:invite][:token]) if params[:invite].present?
  end

  helper_method :invite

  def user_params
    # TODO: Fixme, maybe handled here: https://github.com/markets/invisible_captcha/issues/107
    params[:user].try(:delete, :subtitle) if params.key?(:user)

    params.require(:user).permit(
      :username, :email, :getting_started, :password, :password_confirmation, :language, :disable_mail,
      :show_community_spotlight_in_stream, :auto_follow_back, :auto_follow_back_aspect_id,
      :remember_me
    )
  end
end
