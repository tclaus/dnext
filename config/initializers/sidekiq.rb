# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = AppConfig.get_redis_options

  # Set connection pool to match concurrency
  database_url = ENV.fetch("DATABASE_URL", nil)
  if database_url
    ENV["DATABASE_URL"] = "#{database_url}?pool=#{AppConfig.environment.sidekiq.concurrency.get}"
    ActiveRecord::Base.establish_connection
  end
end

Sidekiq.configure_client do |config|
  config.redis = AppConfig.get_redis_options
end
