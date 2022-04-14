# frozen_string_literal: true

class PostsController < ApplicationController
  layout "with_header"
  before_action :authenticate_user!, only: %i[destroy mentionable]

  rescue_from Diaspora::Exceptions::NonPublic do
    authenticate_user!
  end

  rescue_from Diaspora::Exceptions::NotMine do
    render plain: I18n.t("posts.show.forbidden"), status: :forbidden
  end

  def show
    post = post_service.find!(params[:id])
    post_service.mark_user_notifications(post.id)
    presenter = PostPresenter.new(post, current_user)
    respond_to do |format|
      format.html do
        render locals: {post: presenter}
      end
    end
  end

  private

  def post_service
    @post_service ||= PostService.new(current_user)
  end
end
