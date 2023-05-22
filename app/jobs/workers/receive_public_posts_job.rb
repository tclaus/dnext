# frozen_string_literal: true

class Workers::ReceivePublicPostsJob < Workers::ReceiveBaseJob
  def perform
    Pod.check_all_unchecked!
  end
end
