# frozen_string_literal: true
module Stream
  class Public < Stream::Base

    def title
      I18n.translate("streams.public.title")
    end

    # @return [ActiveRecord::Association<Post>] AR association of posts
    def posts
      @posts ||= Post.all_public_no_nsfw
    end

    # Override base class method
    def aspects
      ["public"]
    end
  end
end
