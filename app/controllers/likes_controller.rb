# frozen_string_literal: true

class LikesController < ApplicationController
  include ApplicationHelper
  before_action :authenticate_user!, except: :index

  rescue_from Diaspora::Exceptions::NonPublic do
    authenticate_user!
  end

  def create
    @like = if like_for_post?
              like_service.create_for_post(post_id)
            elsif like_for_comment?
              like_service.create_for_comment(comment_id)
            else
              raise "Invalid entity type received."
            end
    # TODO: ! Comments
    @post = PostPresenter.new(Post.find(post_id), current_user)
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid
    render plain: I18n.t("likes.create.error"), status: :unprocessable_entity
  else
    respond_to do |format|
      format.html { head :created }
      format.json do
        render json: {
          element_footer: render_to_string(partial: "streams/stream_footer",
                                           locals:  {post: @post},
                                           formats: [:html])
        }
      end
    end
  end

  def destroy
    like = Like.find(like_id)
    if like && like_service.destroy(like.id)
      respond_to do |format|
        format.json do
          post = PostPresenter.new(like.parent, current_user)
          render json: {
            element_footer: render_to_string(partial: "streams/stream_footer",
                                             locals:  {post: post},
                                             formats: [:html])
          }
        end
      end
    else
      render plain: I18n.t("likes.destroy.error"), status: :not_found
    end
  end

  def index
    like = if like_for_post?
             like_service.find_for_post(post_id)
           else
             like_service.find_for_comment(comment_id)
           end
    render json: like
      .includes(author: :profile)
      .as_api_response(:backbone)
  end

  private

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
