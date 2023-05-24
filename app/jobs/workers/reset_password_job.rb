# frozen_string_literal: true

module Workers
  class ResetPasswordJob < Workers::ApplicationJob
    queue_as :urgent

    def perform(user)
      user.send_reset_password_instructions!
    end
  end
end
