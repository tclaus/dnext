# frozen_string_literal: true

module Stream
  class Multi < Stream::Base
    # @return [String]
    def title
      I18n.t("streams.multi.title")
    end

    # @return [String] URL
    def link(opts)
      Rails.application.routes.url_helpers.stream_path(opts)
    end

    def posts
      @posts ||= EvilQuery::Multi.new(user, include_spotlight: include_community_spotlight?).posts
    end

    # emits an enum of the groups which the post appeared
    # :spotlight, :aspects, :tags, :mentioned
    def post_from_group(post)
      streams_included.collect do |source|
        is_in?(source, post)
      end.compact
    end

    private

    def publisher_opts
      if welcome?
        {open: true, prefill: publisher_prefill, public: true}
      else
        {public: user.post_default_public}
      end
    end

    # Generates the prefill for the publisher
    #
    # @return [String]
    def publisher_prefill
      prefill = I18n.t("shared.publisher.new_user_prefill.hello",
                       new_user_tag: I18n.t("shared.publisher.new_user_prefill.newhere"))
      if user.followed_tags.size > 0
        tag_string = user.followed_tags.map {|t| "##{t.name}" }.to_sentence
        prefill << I18n.t("shared.publisher.new_user_prefill.i_like", tags: tag_string)
      end

      if inviter = user.invited_by.try(:person)
        prefill << I18n.t("shared.publisher.new_user_prefill.invited_by")
        prefill << "@{#{inviter.diaspora_handle}}!"
      end

      prefill
    end

    # @return [Boolean]
    def welcome?
      user.getting_started
    end

    # @return [Array<Symbol>]
    def streams_included
      @streams_included ||= lambda do
        array = %i[mentioned aspects followed_tags]
        array << :community_spotlight if include_community_spotlight?
        array
      end.call
    end

    # @return [Symbol]
    def is_in?(sym, post)
      "#{sym}_stream".to_sym if send("#{sym}_post_ids").find {|x| (x == post.id) || (x.to_s == post.id.to_s) }
    end

    # @return [Boolean]
    def include_community_spotlight?
      AppConfig.settings.community_spotlight.enable? && user.show_community_spotlight_in_stream?
    end
  end
end
