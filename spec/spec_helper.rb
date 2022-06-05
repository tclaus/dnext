# frozen_string_literal: true

#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

ENV["RAILS_ENV"] ||= "test"

require File.join(File.dirname(__FILE__), "..", "config", "environment")
require Rails.root.join("spec", "helper_methods")
require "rspec/rails"
require "webmock/rspec"
require "sidekiq/testing"
require "shoulda/matchers"
require "diaspora_federation/schemas"

include HelperMethods

Dir["#{File.dirname(__FILE__)}/shared_behaviors/**/*.rb"].each do |f|
  require f
end

RSpec::Matchers.define_negated_matcher :remain, :change

# ProcessedImage.enable_processing = false
# UnprocessedImage.enable_processing = false

def photo_fixture_name
  @photo_fixture_name = File.join(File.dirname(__FILE__), "fixtures", "button.png")
end

def jwks_file_path
  @jwks_file = File.join(File.dirname(__FILE__), "fixtures", "jwks.json")
end

def valid_client_assertion_path
  @valid_client_assertion = File.join(File.dirname(__FILE__), "fixtures", "valid_client_assertion.txt")
end

def client_assertion_with_tampered_sig_path
  @client_assertion_with_tampered_sig = File.join(File.dirname(__FILE__), "fixtures",
                                                  "client_assertion_with_tampered_sig.txt")
end

def client_assertion_with_nonexistent_kid_path
  @client_assertion_with_nonexistent_kid = File.join(File.dirname(__FILE__), "fixtures",
                                                     "client_assertion_with_nonexistent_kid.txt")
end

def client_assertion_with_nonexistent_client_id_path
  @client_assertion_with_nonexistent_client_id = File.join(File.dirname(__FILE__), "fixtures",
                                                           "client_assertion_with_nonexistent_client_id.txt")
end

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
fixture_builder_file = "#{File.dirname(__FILE__)}/support/fixture_builder.rb"
support_files = Dir["#{File.dirname(__FILE__)}/support/**/*.rb"] - [fixture_builder_file]
support_files.each {|f| require f }
require fixture_builder_file

RSpec.configure do |config|
  config.mock_with :rspec

  config.example_status_persistence_file_path = "tmp/rspec-persistance.txt"

  config.render_views

  config.before(:each) do
    I18n.locale = :en
    stub_request(:post, "https://pubsubhubbub.appspot.com/")
    stub_request(
      :get,
      "https://example.com/.well-known/webfinger?resource=acct:bob@example.com"
    )
    stub_request(:post, "http://example.net/receive/users/").
      with(
        headers: {
          'Content-Type'=>'application/json',
          'Expect'=>'',
        }).
      to_return(status: 200, body: "", headers: {})

    stub_request(
      :get,
      "https://example.com/.well-known/host-meta"
    )
    stub_request(:get, "https://api.deepl.com/v2/languages")
      .with(
        headers: {
          "Accept"          => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "User-Agent"      => "Ruby"
        }
      )
      .to_return(status: 200, body: '[{"language":"de", "name": "German", "supports_formality": true}]', headers: {})
    stub_request(:any, /localhost:9200/)
      .to_return(status: 200, body: "", headers: {})

    $process_queue = false
  end

  config.expect_with :rspec do |expect_config|
    expect_config.syntax = :expect
  end

  config.after(:all) do
    `rm -rf #{Rails.root}/tmp/uploads/*`
  end

  # Reset overridden settings
  config.after(:each) do
    AppConfig.reset_dynamic!
  end

  # Reset test mails
  config.after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  config.include FactoryBot::Syntax::Methods

  config.include JSON::SchemaMatchers
  # TODO: Activate Schema tests in a separate PR
  #  config.json_schemas[:archive_schema] = ArchiveValidator::SchemaValidator::JSON_SCHEMA
  config.json_schemas[:api_v1_schema] = "lib/schemas/api_v1.json"

  JSON::Validator.add_schema(
    JSON::Schema.new(
      DiasporaFederation::Schemas.federation_entities,
      Addressable::URI.parse(DiasporaFederation::Schemas::FEDERATION_ENTITIES_URI)
    )
  )
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

shared_context suppress_csrf_verification: :none do
  before do
    ActionController::Base.allow_forgery_protection = true
  end
end

begin
  require "factory_bot_rails"
rescue LoadError
end
