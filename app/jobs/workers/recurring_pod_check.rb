# frozen_string_literal: true

module Workers
  class RecurringPodCheck < Workers::ApplicationJob
    sidekiq_options queue: :low

    def perform
      Pod.check_all!
    end
  end
end
