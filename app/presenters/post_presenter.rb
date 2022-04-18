# frozen_string_literal: true

class PostPresenter < BasePresenter
  attr_accessor :post

  def initialize(presentable, current_user=nil)
    @post = presentable
    super
  end

  def page_title
    post_page_title @post
  end

  def likes
    LikeService.new(current_user)
               .find_for_post(@post.id)
               .limit(30)
  end

  def reshares
    ReshareService.new(current_user)
                  .find_for_post(@post.id)
                  .limit(30)
  end

end
