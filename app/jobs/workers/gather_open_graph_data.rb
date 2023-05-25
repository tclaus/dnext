# frozen_string_literal: true

module Workers
  class GatherOpenGraphData < Workers::ApplicationJob
    queue_as :medium

    def perform(post_id, url, retry_count=1)
      post = Post.find(post_id)
      post.open_graph_cache = OpenGraphCache.find_or_create_by(url: url)
      update_language_from_og(post) if post.language_id.nil?
      post.save
    rescue ActiveRecord::RecordNotFound
      # User created a post and deleted it right afterwards before we
      # we had a chance to run the job.
      # On the other hand sometimes the job runs before the Post is
      # fully persisted. So we just reduce the amount of retries.
      GatherOpenGraphData.perform_in(1.minute, post_id, url, retry_count + 1) unless retry_count > 3
    end

    private

    def update_language_from_og(post)
      return if post.open_graph_cache&.locale.nil?

      post.language_id = post.open_graph_cache.locale
    end
  end
end
