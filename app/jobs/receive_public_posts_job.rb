# frozen_string_literal: true

class ReceivePublicPostsJob < ReceiveBaseJob
  def perform
    Pod.check_all_unchecked!
  end
end
