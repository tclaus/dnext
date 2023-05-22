# frozen_string_literal: true

class Workers::GatherOEmbedData < Workers::ApplicationJob
  sidekiq_options queue: :medium

  def perform(post_id, url, retry_count=1)
    post = Post.find(post_id)
    post.o_embed_cache = OEmbedCache.find_or_create_by(url: url)
    post.save
  rescue ActiveRecord::RecordNotFound
    # User created a post and deleted it right afterwards before we
    # we had a chance to run the job.
    # On the other hand sometimes the job runs before the Post is
    # fully persisted. So we just reduce the amount of retries.
    GatherOEmbedData.perform_in(1.minute, post_id, url, retry_count + 1) unless retry_count > 3
  end
end
