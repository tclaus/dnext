# frozen_string_literal: true

module Workers
  class RecurringPodCheck < Workers::ApplicationJob
    queue_as :low

    def perform
      Pod.check_all!
    end
  end
end
