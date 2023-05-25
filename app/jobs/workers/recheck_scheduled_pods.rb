# frozen_string_literal: true

module Workers
  class RecheckScheduledPods < Workers::ApplicationJob
    queue_as :low

    def perform
      Pod.check_scheduled!
    end
  end
end
