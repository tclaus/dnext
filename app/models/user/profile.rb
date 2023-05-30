# frozen_string_literal: true

class User
  module Profile
    # TODO: test here - can this be called?
    # Better: Write this as service files?
    def update_profile(params)
      if photo = params.delete(:photo)
        photo.update(pending: false) if photo.pending
        params[:image_url] = photo.url(:thumb_large)
        params[:image_url_medium] = photo.url(:thumb_medium)
        params[:image_url_small] = photo.url(:thumb_small)
      end

      params.stringify_keys!
      params.slice!(*(Profile.column_names + %w[tag_string date]))
      if profile.update(params)
        deliver_profile_update
        true
      else
        false
      end
    end

    def update_profile_with_omniauth(user_info)
      update_profile(profile.from_omniauth_hash(user_info))
    end

    def deliver_profile_update(opts={})
      Diaspora::Federation::Dispatcher.defer_dispatch(self, profile, opts)
    end

    def basic_profile_present?
      tag_followings.any? || profile[:image_url]
    end
  end
end
