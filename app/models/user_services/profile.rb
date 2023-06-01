# frozen_string_literal: true

module UserServices
  class Profile
    # @param [User] user up profiles for the user
    def initialize(user)
      @user = user
    end

    def onboard_user?
      user.getting_started? && !basic_profile_present?
    end

    def update_profile_with_omniauth(user_info)
      update_profile(user.profile.from_omniauth_hash(user_info))
    end

    def update_profile(params)
      if photo = params.delete(:photo)
        photo.update(pending: false) if photo.pending
        params[:image_url]        = photo.url(:thumb_large)
        params[:image_url_medium] = photo.url(:thumb_medium)
        params[:image_url_small]  = photo.url(:thumb_small)
      end

      params.stringify_keys!
      params.slice!(*(Profile.column_names + %w[tag_string date]))
      if user.profile.update(params)
        deliver_profile_update
        true
      else
        false
      end
    end

    def deliver_profile_update(opts={})
      Diaspora::Federation::Dispatcher.defer_dispatch(user, user.profile, opts)
    end

    # A user should follow at least one person or should have a profile image
    def basic_profile_present?
      user.tag_followings.any? || user.profile[:image_url]
    end

    private

    attr_reader :user
  end
end
