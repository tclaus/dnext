require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Diaspora
  class Application < Rails::Application
    # Tell Fixture Builder where to set fixtures
    ENV["FIXTURES_PATH"] = "spec/fixtures"

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    config.eager_load_paths << Rails.root.join("lib")

    # Setup action mailer early
    config.action_mailer.default_url_options = {
      # host: AppConfig.pod_uri.authority,
      # protocol: AppConfig.pod_uri.scheme
    }
    config.active_job.queue_adapter = :sidekiq

    # Support unencrypted data in encrypted fields
    # Used for  plain_otp_secret
    config.active_record.encryption.support_unencrypted_data = true
  end
end

Rails.application.routes.default_url_options[:host] = AppConfig.pod_uri.host
Rails.application.routes.default_url_options[:port] = AppConfig.pod_uri.port
