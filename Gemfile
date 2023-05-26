# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) {|repo| "https://github.com/#{repo}.git" }

ruby "3.1.4"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.0"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use pg as the database for Active Record
gem "pg", "~> 1.5.3"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 6.2.2"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 5.0", ">= 5.0.6"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Sass to process CSS
gem "sassc-rails", "~> 2.1", ">= 2.1.2"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

gem "bootstrap", "~> 5.1.3"
gem "haml"

# Pagination / infinite scroller support in stream
gem "pagy", "~> 5.6", ">= 5.6.6"

# Rendering
gem "entypo-rails", git: "https://github.com/wangliyao/entypo-rails" # Entypo-Rails can not directly used for Rails > 6
gem "local_time"
gem "open_graph_reader", "~> 0.7.2"
gem "ruby-oembed", "~> 0.15.0"

# Markdown renderer
gem "redcarpet", "~> 3.5", ">= 3.5.1"
gem "twitter-text", "~> 3.1.0"

# Localization helpers
gem "http_accept_language", "~> 2.1", ">= 2.1.1"
gem "rails-i18n", "~> 7.0", ">= 7.0.3"

# Detect language of text
gem "cld3", "~> 3.4", ">= 3.4.2"
gem "ffi", "~> 1.15", ">= 1.15.5"

# Configuration
gem "configurate", "~>0.5.0"
gem "toml-rb", "~> 2.1.0"

# Taggable Posts
gem "acts-as-taggable-on", "~> 9.0", ">= 9.0.1"

# Uris and HTTP
gem "addressable", "~> 2.8", require: "addressable/uri"
gem "faraday", "~> 2.7", ">= 2.7.4"
gem "faraday-cookie_jar",       "0.0.7"
gem "faraday-follow_redirects", "0.3.0"

# Authentication
gem "attr_encrypted", "~> 4.0"
gem "devise", "~>4.8.1"
gem "devise-i18n", "~> 1.10", ">= 1.10.1"
gem "devise_last_seen"
gem "devise-two-factor", "~>4.0", ">=4.0.2"
# QR Code generation for 2FA.
# See: https://github.com/whomwah/rqrcode
gem "rqrcode", "~> 2.1", ">= 2.1.1"
#
# Captcha

gem "invisible_captcha", "~> 2.0"

# Background processing
gem "sidekiq", "~> 7.1"
gem "sidekiq-cron", "~> 1.10", ">= 1.10.1"

# Federation
gem "diaspora_federation", "~> 1.0", ">= 1.0.1"
gem "timecop", "~> 0.9.5"

# frozen_string_literal: true
group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  # gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "dotenv", "~> 2.7", ">= 2.7.6"
  gem "factory_bot_rails", "~> 6.2"
  gem "fixture_builder", "~> 0.5.2"
  gem "rspec-rails", "~> 5.1"

  gem "rubocop", require: false
  gem "rubocop-rails", "~> 2.13", ">= 2.13.2", require: false
  gem "rubocop-rspec", "~> 2.11", ">= 2.11.1", require: false

  # see https://github.com/rubysec/bundler-audit#readme
  gem "bundler-audit", "~> 0.9.1"

  gem "brakeman", "~> 5.2", ">= 5.2.3"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]

  # Faking literaly everything https://github.com/faker-ruby/faker
  gem "faker", "~> 2.21"

  # Web Driver https://github.com/rubycdp/cuprite
  gem "cuprite", require: false

  # see: https://github.com/cucumber/cucumber-rails
  gem "cucumber-rails", require: false
  # database_cleaner is not required, but highly recommended
  gem "database_cleaner", require: false

  gem "capybara"
  gem "diaspora_federation-json_schema", "~> 0.3.0"
  gem "json-schema-rspec", "0.0.4"
  gem "rspec-json_expectations", "~> 2.1"
  gem "shoulda-matchers", "~> 5.1"
  gem "webmock", "3.14.0", require: false
end
