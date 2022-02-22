# This file was generated by the `rails generate rspec:install` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# See https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

ENV["RAILS_ENV"] ||= "test"

require File.join(File.dirname(__FILE__), "..", "config", "environment")
require Rails.root.join("spec", "helper_methods")
require "rspec/rails"
require "webmock/rspec"
# require "sidekiq/testing"
# require "shoulda/matchers"
require "diaspora_federation/schemas"

include HelperMethods

Dir["#{File.dirname(__FILE__)}/shared_behaviors/**/*.rb"].each do |f|
  require f
end

RSpec::Matchers.define_negated_matcher :remain, :change

# ProcessedImage.enable_processing = false
# UnprocessedImage.enable_processing = false

def alice
  @alice ||= User.find_by(username: "alice")
end

def bob
  @bob ||= User.find_by(username: "bob")
end

def eve
  @eve ||= User.find_by(username: "eve")
end

def local_luke
  @local_luke ||= User.find_by(username: "luke")
end

def local_leia
  @local_leia ||= User.find_by(username: "leia")
end

def remote_raphael
  @remote_raphael ||= Person.find_by(diaspora_handle: "raphael@remote.net")
end

def peter
  @peter ||= User.find_by(username: "peter")
end

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
