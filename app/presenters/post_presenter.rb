# frozen_string_literal: true

class PostPresenter < BasePresenter
  attr_accessor :post

  # @param [Post] presentable A post or a comment
  # @param [User] current_user
  def initialize(presentable, current_user=nil)
    @post = presentable
    super
  end

  def page_title
    post_page_title @post
  end

  def own_interaction_state
    if current_user
      {
        liked:      @post.likes.exists?(author: current_user.person),
        reshared:   @post.reshares.exists?(author: current_user.person),
        subscribed: participates?,
        reported:   @post.reports.exists?(user: current_user)
      }
    else
      {
        liked:      false,
        reshared:   false,
        subscribed: false,
        reported:   false
      }
    end
  end

  def likes
    LikeService.new(current_user)
               .find_for_post(@post.id)
               .limit(30)
  end

  def own_like
    @post.likes.find_by(author: current_user.person)
  end

  def reshares
    ReshareService.new(current_user)
                  .find_for_post(@post.id)
                  .limit(30)
  end

  def participates?
    user_signed_in? && current_user.participations.exists?(target_id: @post)
  end

  def user_signed_in?
    current_user.present?
  end
end
