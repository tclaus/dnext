# frozen_string_literal: true

class PostToServiceJob < ApplicationJob
  sidekiq_options queue: :medium

  def perform(service_id, post_id, url)
    service = Service.find_by(id: service_id)
    post = Post.find_by(id: post_id)
    service.post(post, url)
  end
end