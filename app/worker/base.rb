module Workers
  class Base
    include Sidekiq::Worker
    sidekiq_options backtrace: (bt = AppConfig.environment.sidekiq.backtrace.get) && bt.to_i,
      retry: (rt = AppConfig.environment.sidekiq.retry.get) && rt.to_i

    include Diaspora::Logging
  end
end
