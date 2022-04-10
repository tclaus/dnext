module EvilQuery
  class Multi < Base
    def initialize(user, include_spotlight: true)
      super(user)
      @include_spotlight = include_spotlight
    end

    def posts
      p = Post.union(aspects, visible_shareable, followed_tags, mentioned_posts, community_spotlight_posts!)
      p = exclude_hidden_content(p)
      ignore_blocked_pods(p)
    end

    def aspects
      aspect_ids = @user.aspects.ids
      Post.where(public: true, author_id: Person.in_aspects(aspect_ids).ids)
    end

    def visible_shareable
      Post.where(id:
                     ShareVisibility.for_a_user(@user).where(shareable_type: :Post)
                     .select(:shareable_id))
    end

    def followed_tags
      StatusMessage.public_any_tag_stream(@user.followed_tag_ids)
    end

    def mentioned_posts
      StatusMessage.where_person_is_mentioned(@user.person)
    end

    # Returns all posts authored by a person with the community spotlight role
    # @return [ActiveRecord::Relation<Post>]
    def community_spotlight_posts!
      Post.where(author_id: Person.community_spotlight)
    end
  end
end
