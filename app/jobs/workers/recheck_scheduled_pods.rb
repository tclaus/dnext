# frozen_string_literal: true

module Workers
  class RecheckScheduledPods < Workers::ApplicationJob
    sidekiq_options queue: :low

    def perform
      Pod.check_scheduled!
    end
  end
end
