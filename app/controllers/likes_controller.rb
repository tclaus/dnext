# frozen_string_literal: true

class LikesController < ApplicationController
  include ApplicationHelper
  include PostInteractionRender

  before_action :authenticate_user!, except: :index

  rescue_from Diaspora::Exceptions::NonPublic do
    authenticate_user!
  end

  def create
    if like_for_post?
      create_for_post
    elsif like_for_comment?
      create_for_comment
    else
      raise "Invalid entity type received."
    end
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid
    render plain: I18n.t("likes.create.error"), status: :unprocessable_entity
  end

  def destroy
    like = Like.find(like_id)
    if like && like_service.destroy(like.id)
      return response_for_comment(like.parent) if like.target_type.eql?("Comment")

      return response_for_post(like.parent) if like.target_type.eql?("Post")
    else
      render plain: I18n.t("likes.destroy.error"), status: :not_found
    end
  end

  private

  def create_for_comment
    like = like_service.create_for_comment(comment_id)
    response_for_comment(like.parent)
  end

  def create_for_post
    like = like_service.create_for_post(post_id)
    response_for_post(like.parent)
  end

  def response_for_comment(comment)
    comment.reload
    respond_to do |format|
      format.html { head :created }
      format.json do
        comment = CommentPresenter.new(comment, current_user)
        render json: {
          element_footer: render_to_string(partial: "streams/comments/comment_interactions",
                                           locals:  {comment: comment},
                                           formats: [:html])
        }
      end
    end
  end

  def like_id
    params[:id]
  end

  def post_id
    params[:post_id]
  end

  def comment_id
    params[:comment_id]
  end

  def like_for_post?
    params[:post_id].present?
  end

  def like_for_comment?
    params[:comment_id].present?
  end

  def like_service
    @like_service ||= LikeService.new(current_user)
  end
end
