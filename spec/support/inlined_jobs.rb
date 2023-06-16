# frozen_string_literal: true

require "sidekiq/testing"

module HelperMethods
  def inlined_jobs
    Sidekiq::Worker.clear_all
    result = yield Sidekiq::Worker
    Sidekiq::Worker.drain_all
    result
  end
end
