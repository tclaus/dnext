# frozen_string_literal: true

class CommentPresenter < BasePresenter
  # @param [Comment] presentable A post or a comment
  # @param [User] current_user
  def initialize(presentable, current_user=nil)
    @comment = presentable
    super
  end

  # CommentPresenter.as_collection(@post.comments.order("created_at ASC")
  def own_interaction_state
    if current_user
      {
        liked: @comment.likes.exists?(author: current_user&.person)
      }
    else
      {
        liked:    false,
        reported: false
      }
    end
  end

  def likes
    LikeService.new(current_user)
               .find_for_post(@comment.id)
               .limit(30)
  end

  def own_like
    @comment.likes.find_by(author: current_user&.person)
  end
end
