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
        liked:      @post.likes.exists?(author: current_user&.person),
        reshared:   @post.reshares.exists?(author: current_user&.person),
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

  def last_three_comments
    post.last_three_comments.map do |comment|
      CommentPresenter.new(comment, current_user)
    end
  end

  # @return [A limited list of likes for this post]
  def likes
    LikeService.new(current_user)
               .find_for_post(@post.id)
               .limit(30)
  end

  def own_like
    @post.likes.find_by(author: current_user&.person)
  end

  def reshares
    ReshareService.new(current_user)
                  .find_for_post(@post.id)
                  .limit(30)
  end

  def user_can_reshare?
    return false unless post.public # Dont reshare private posts
    return false if post.author.eql?(current_user&.person) # Dont reshare own posts
    # Dont reshare if already a share exists
    return false if post.is_a?(StatusMessage) && post.reshares.exists?(author: current_user&.person)
    return false if post.is_a?(Reshare) && !reshare_allowed?(post)

    true
  end

  def participates?
    user_signed_in? && current_user.participations.exists?(target_id: @post)
  end

  def user_signed_in?
    current_user.present?
  end

  def root_comments
    post.root_comments.map do |comment|
      CommentPresenter.new(comment, current_user)
    end
  end

  private

  def reshare_allowed?(reshare)
    #  Dont reshare if reshares root parent does not exist
    return false if reshare.root.nil?
    # Dont reshare if root post is own post
    return false if reshare.root.author.eql?(current_user&.person)

    true
  end
end
