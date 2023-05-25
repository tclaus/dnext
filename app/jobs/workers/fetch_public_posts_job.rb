# frozen_string_literal: true

# Fetches public posts from a diaspora Id
module Workers
  class FetchPublicPostsJob < Workers::ApplicationJob
    queue_as :medium

    def perform(diaspora_id)
      Diaspora::Fetcher::Public.new.fetch!(diaspora_id)
    end
  end
end
