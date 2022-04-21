# frozen_string_literal: true

class ResetPasswordJob < ApplicationJob
  queue_as :urgent

  def perform(user)
    user.send_reset_password_instructions!
  end
end
