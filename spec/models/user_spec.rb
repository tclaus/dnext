require "rails_helper"

describe User, type: :model do
  include ActiveJob::TestHelper

  describe ".build" do
    context "with valid parameters" do
      before do
        params = {
          username: "Ohai",
          email: "ohai@example.com",
          password: "password",
          password_confirmation: "password"
        }
        @user = User.build(params)
      end

      it "does not save" do
        expect(@user).to be_a_new(User)
        expect(@user.person.persisted?).to be false
        expect(User.find_by(username: "ohai")).to be_nil
      end
      it "saves successfully" do
        expect(@user).to be_valid
        expect(@user.save).to be_truthy
        expect(@user.person.persisted?).to be_truthy
        expect(User.find_by(username: "ohai")).to eq(@user)
      end
    end
    describe "with invalid params" do
      before do
        @invalid_params = {
          username: "ohai",
          email: "ohai@example.com",
          password: "password",
          password_confirmation: "wrongpasswordz",
          person: {profile: {first_name: "", last_name: ""}}
        }
      end

      it "raises no error" do
        expect { User.build(@invalid_params) }.not_to raise_error
      end

      it "does not save" do
        expect(User.build(@invalid_params).save).to be false
      end

      it "does not save a person" do
        expect { User.build(@invalid_params) }.not_to change(Person, :count)
      end

      it "does not generate a key" do
        # expect(User).to receive(:generate_keys).exactly(0).times
        u = User.build(@invalid_params)
        expect(u.serialized_private_key).to be_blank
      end
    end
  end

  describe "#destroy" do
    it "raises error" do
      params = {
        username: "Ohai",
        email: "ohai@example.com",
        password: "password",
        password_confirmation: "password"
      }
      user = User.build(params)

      expect {
        user.destroy
      }.to raise_error "Never destroy users!"
    end
  end

  describe "send password instructions" do
    it "should send instructions async" do
      user = FactoryBot.create(:user)
      assert_enqueued_with(job: ResetPasswordJob, args: [user]) do
        user.send_reset_password_instructions
      end
    end
  end

  describe "validation" do
    describe "of language" do
      after do
        I18n.locale = :en
      end

      it "requires availability" do
        alice.language = "some invalid language"
        expect(alice).not_to be_valid
      end

      it "should save with current language if blank" do
        I18n.locale = :fr
        user = User.build username: "max", email: "foo@bar.com", password: "password", password_confirmation: "password"
        expect(user.language).to eq("fr")
      end

      it "should save with language what is set" do
        I18n.locale = :fr
        user = User.build(username: "max", email: "foo@bar.com", password: "password",
                          password_confirmation: "password", language: "de")
        expect(user.language).to eq("de")
      end
    end

  end

end
