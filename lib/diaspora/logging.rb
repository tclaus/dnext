# frozen_string_literal: true

# a logging mixin providing the logger
module Diaspora
  module Logging
    def logger
      Logging.logger
    end

    def self.logger
      @logger ||= Rails.logger
    end
  end
end
