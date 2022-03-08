# frozen_string_literal: true

module Stream
  class Public < Stream::Base
    def title
      I18n.t("streams.public.title")
    end

    # @return [ActiveRecord::Association<Post>] AR association of posts
    def posts
      @posts ||= Post.all_public_no_nsfw
      posts_by_language
    end

    def posts_by_language
      languages = language_service.language_for_stream
      return @posts if languages.empty?

      comma_separated = languages.to_s.delete("[").delete("]").gsub('"', "'")
      @posts.where("(posts.language_id in (#{comma_separated})
                   or posts.language_id is null)")
    end

    # Override base class method
    def aspects
      ["public"]
    end

    private

    def language_service
      @language_service ||= StreamLanguageService.new(@user)
    end
  end
end
