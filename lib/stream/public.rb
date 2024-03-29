# frozen_string_literal: true

module Stream
  class Public < Stream::Base
    def title
      I18n.t("streams.public.title")
    end

    # @return [ActiveRecord::Association<Post>] AR association of posts
    def posts
      @posts ||= if user.nil?
                   Post.all_public_no_nsfw
                 else
                   Post.all_public
                 end
      posts_by_language
      for_a_stream
    end

    # Override base class method
    def aspects
      ["public"]
    end

    private

    def for_a_stream
      Post.for_a_stream(@posts, user)
    end

    def posts_by_language
      languages = language_service.language_for_stream
      return @posts if languages.empty?

      comma_separated = languages.to_s.delete("[").delete("]").gsub('"', "'")
      @posts = @posts.where("(posts.language_id in (#{comma_separated})
                   or posts.language_id is null)")
    end

    def language_service
      @language_service ||= StreamLanguageService.new(@user)
    end
  end
end
