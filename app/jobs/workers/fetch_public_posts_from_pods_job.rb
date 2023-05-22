# frozen_string_literal: true

class Workers::FetchPublicPostsFromPodsJob < Workers::ApplicationJob
  include Diaspora::Logging

  sidekiq_options queue: :medium

  def perform
    retrieve_public_posts_for_all
  end

  def retrieve_public_posts_for_all
    logger.info("Retrieve posts from all pods")
    fetch_posts_from_pod = Diaspora::Fetcher::PublicPostsFromPod.new

    Pod.where(status: 1)
       .find_in_batches(batch_size: 20) do |batch|
      batch.each do |pod_to_scan|
        logger.info "Find posts from pod #{pod_to_scan}"
        fetch_posts_from_pod.fetch!(pod_to_scan)
      end
    end
  end
end
