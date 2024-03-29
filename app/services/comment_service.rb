# frozen_string_literal: true

class CommentService
  def initialize(user = nil)
    @user = user
  end

  def create(post_id, text)
    post = post_service.find!(post_id)
    user.comment!(post, text)
  end

  def find_for_post(post_id)
    post_service.find!(post_id).comments.for_a_stream
  end

  def find!(id_or_guid)
    Comment.find_by!(comment_key(id_or_guid) => id_or_guid)
  end

  def destroy(comment_id)
    comment = Comment.find(comment_id)
    if user.owns?(comment) || user.owns?(comment.parent)
      user.retract(comment)
      true
    else
      false
    end
  end

  def destroy!(comment_guid)
    comment = find!(comment_guid)
    if user.owns?(comment)
      user.retract(comment)
    elsif user.owns?(comment.parent)
      user.retract(comment)
    elsif comment
      raise ActiveRecord::RecordInvalid
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  private

  attr_reader :user

  # We can assume a guid is at least 16 characters long as we have guids set to hex(8) since we started using them.
  def comment_key(id_or_guid)
    id_or_guid.to_s.length < 16 ? :id : :guid
  end

  def post_service
    @post_service ||= PostService.new(user)
  end
end