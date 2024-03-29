# frozen_string_literal: true

module Diaspora
  module Commentable
    def self.included(model)
      model.instance_eval do
        has_many :comments, -> { order created_at: :asc }, as: :commentable, class_name: "Comment", dependent: :destroy
      end
    end

    # @return [Array<Comment>]
    def last_three_comments
      return [] if comments_count == 0

      # DO NOT USE .last(3) HERE.  IT WILL FETCH ALL COMMENTS AND RETURN THE LAST THREE
      # INSTEAD OF DOING THE FOLLOWING, AS EXPECTED (THX AR):
      comments.order("created_at DESC").limit(3).includes(author: :profile).reverse
    end

    def root_comments
      comments
        .where(thread_parent_guid: nil)
        .order(created_at: :asc)
    end

    # @return [Integer]
    def update_comments_counter
      self.class.where(id: id)
          .update_all(comments_count: comments.count) # rubocop:disable Rails/SkipsModelValidations
    end

    def comments_authors
      Person.where(id: comments.select(:author_id).distinct)
    end
  end
end
