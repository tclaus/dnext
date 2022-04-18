# frozen_string_literal: true

module Diaspora
  module Exceptions
    # the post in question is not public, and that is somehow a problem
    class NonPublic < StandardError
    end

    # the account was closed and that should not be the case if we want
    # to continue
    class AccountClosed < StandardError
    end

    # something that should be accessed does not belong to the current user and
    # that prevents further execution
    class NotMine < StandardError
    end
  end
end
