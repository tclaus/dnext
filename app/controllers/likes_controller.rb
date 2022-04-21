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
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid
    render plain: I18n.t("likes.create.error"), status: :unprocessable_entity
  else
    respond_to do |format|
      format.html { head :created }
    end
  end

  def destroy
    if like_service.destroy(params[:id])
      head :no_content
    else
      render plain: I18n.t("likes.destroy.error"), status: :not_found
    end
  end

  def index
    like = if params[:post_id]
             like_service.find_for_post(params[:post_id])
           else
             like_service.find_for_comment(params[:comment_id])
           end
    render json: like
      .includes(author: :profile)
      .as_api_response(:backbone)
  end

  private

  # @return [Numeric] A post Id or the Id of a reshare
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
