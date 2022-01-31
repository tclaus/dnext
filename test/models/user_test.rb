require "test_helper"

class UserTest < ActiveSupport::TestCase
  describe "sign up" do
    before do
      params = {username: "ohai",
                email: "ohai@example.com",
                password: "password",
                password_confirmation: "password",
                person: {profile: {first_name: "O",
                                   last_name: "Hai"}}}
      @user = User.build(params)
    end
  end
  describe "#destroy" do
    it "raises error" do
      expect {
        alice.destroy
      }.to raise_error "Never destroy users!"
    end
  end
end
