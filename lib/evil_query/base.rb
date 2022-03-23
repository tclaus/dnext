# frozen_string_literal: true

module EvilQuery
  class Base
    include Diaspora::Logging

    # Adds a relation that blocks blocked pods
    # @param [ActiveRecord::Relation] shareable_relation
    # @return [ActiveRecord::Relation]
    def ignore_blocked_pods(shareable_relation)
      shareable_relation.left_outer_joins(author: [:pod])
                        .where("(pods.blocked = false or pods.blocked is null)")
    end
  end
end
