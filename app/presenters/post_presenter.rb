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
end
