# frozen_string_literal: true

class ReshareService
  attr_accessor :user

  def initialize(user=nil)
    @user = user
  end

  def create(post_id, text="")
    post = post_service.find!(post_id)
    post = post.absolute_root if post.is_a? Reshare
    user.reshare!(post, text: text)
  end

  def find_for_post(post_id)
    reshares = post_service.find!(post_id).reshares
    user ? reshares.order(Arel.sql("author_id = #{user.person.id} DESC")) : reshares
  end

  private

  def post_service
    @post_service ||= PostService.new(user)
  end
end
