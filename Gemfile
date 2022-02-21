source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.0.3"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.0.0"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use pg as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 5.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 4.0"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Sass to process CSS
gem "sassc-rails"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

gem "bootstrap", "~> 5.1.3"
gem "haml"

# Pagination / infinite scroller support in stream
gem "local_time"
gem "pagy", "~> 5.6", ">= 5.6.6"

# Rendering
gem "open_graph_reader", "~> 0.7.2"
gem "ruby-oembed", "~> 0.15.0"
gem "entypo-rails", github: "wangliyao/entypo-rails" # Entypo-Rails can not directly used for Rails > 6

# Markdown renderer
gem "redcarpet", "~> 3.5", ">= 3.5.1"
gem "twitter-text", "~> 3.1.0"

# Configuration

gem "configurate", "~>0.5.0"
gem "toml-rb", "~> 2.1.0"

gem "acts-as-taggable-on", github: "mbleigh/acts-as-taggable-on"

# Process Management
gem "eye", "~> 0.10.0"

# Uris and HTTP
gem "addressable", "~> 2.8"

# Authentication
gem "devise", "~>4.8.1"
gem "devise-i18n", "~> 1.10", ">= 1.10.1"
gem "devise_last_seen"
# gem "devise-two-factor", github: "kivanio/devise-two-factor" # Rails 7 support currently not included in main

gem "rqrcode", "~> 2.1"
#
# Captcha

gem "invisible_captcha", "~> 2.0"

# Background processing
gem "sidekiq", "~> 6.4", ">= 6.4.1"

# frozen_string_literal: true
group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri mingw x64_mingw]
  gem "dotenv", "~> 2.7", ">= 2.7.6"
  gem "rspec-rails", "~> 5.1"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  gem "rubocop", "~> 1.24"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "factory_bot_rails", "~> 6.2"
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end
