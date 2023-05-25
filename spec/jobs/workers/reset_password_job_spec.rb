# frozen_string_literal: true

require "rails_helper"

describe Workers::ResetPasswordJob do
  it "sends password reset instructions" do
    user = create(:user)
    expect(user).to receive(:send_reset_password_instructions!)
    Workers::ResetPasswordJob.perform_now(user)
  end
end
