# frozen_string_literal: true

module EvilQuery
  class Base
    attr_accessor :user

    include Diaspora::Logging

    def initialize(user)
      @user = user
    end

    # Adds a relation that blocks blocked pods. Nothing should be shown from any pod that is blocked by admin.
    # @param [ActiveRecord::Relation] shareable_relation
    # @return [ActiveRecord::Relation]
    def ignore_blocked_pods(shareable_relation)
      shareable_relation.left_outer_joins(author: [:pod])
                        .where("(pods.blocked = false or pods.blocked is null)")
    end

    # Adds a filter to any relation of posts to filter blocked or hidden content.
    # @param [ActiveRecord:Relation] An AR of Posts.
    # @return [ActiveRecord] Of posts filtered by blocked User or hidden posts.
    def exclude_hidden_content(relation)
      Post.for_a_stream(relation, @user)
    end
  end
end
