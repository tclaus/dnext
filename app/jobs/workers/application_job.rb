# frozen_string_literal: true

module Workers
  class ApplicationJob < ActiveJob::Base
    # Automatically retry jobs that encountered a deadlock
    retry_on ActiveRecord::Deadlocked

    # Most jobs are safe to ignore if the underlying records are no longer available
    discard_on ActiveJob::DeserializationError, ActiveRecord::RecordNotUnique

    sidekiq_options retry: 5
  end
end
