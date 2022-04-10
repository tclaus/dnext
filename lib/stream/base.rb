# frozen_string_literal: true

module Stream
  class Base
    TYPES_OF_POST_IN_STREAM = %w[StatusMessage Reshare].freeze
    attr_accessor :user

    def initialize(user, _opts={})
      @user = user
    end

    # required to implement said stream
    def link(_opts={})
      "change me in lib/base_stream.rb!"
    end

    def post_from_group(_post)
      []
    end

    # @return [String]
    def title
      "a title"
    end

    # @return [ActiveRecord::Relation<Post>]
    def stream_posts
      ordered_posts
    end

    def ordered_posts
      posts.order(created_at: :desc)
    end

    # Should be overwritten in classes
    # @return [ActiveRecord::Relation<Post>]
    def posts
      # should never be called directly
      Post.none
    end

    # NOTE: MBS bad bad methods the fact we need these means our views are foobared. please kill them and make them
    # private methods on the streams that need them
    def aspects
      user.post_default_aspects
    end

    # @return [Aspect] The first aspect in #aspects
    def aspect
      aspects.first
    end

    protected

    # @return [void]
    def like_posts_for_stream!(posts)
      return posts unless @user

      likes = Like.where(author_id: @user.person_id, target_id: posts.map(&:id), target_type: "Post")

      like_hash = likes.index_by(&:target_id)

      posts.each do |post|
        post.user_like = like_hash[post.id]
      end
    end
  end

  # @return [Hash]
  def publisher_opts
    {}
  end

  # Memoizes all Contacts present in the Stream
  #
  # @return [Array<Contact>]
  def contacts_in_stream
    @contacts_in_stream ||= Contact.where(user_id: user.id, person_id: people.map(&:id)).load
  end
end
