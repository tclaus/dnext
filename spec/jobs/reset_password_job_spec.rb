require "rails_helper"

describe ResetPasswordJob, type: :job do
  it "sends password reset instructions" do
    user = FactoryBot.create(:user)
    expect(user).to receive(:send_reset_password_instructions!)
    ResetPasswordJob.perform_now(user)
  end
end
