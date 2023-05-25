# frozen_string_literal: true

module Workers
  class ReceivePublicPostsJob < Workers::ReceiveBaseJob
    def perform
      Pod.check_all_unchecked!
    end
  end
end
