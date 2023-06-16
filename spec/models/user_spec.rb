# frozen_string_literal: true

describe User do
  include ActiveJob::TestHelper

  describe ".build" do
    context "with valid parameters" do
      let(:user) {
        params = {
          username:              "Ohai",
          email:                 "ohai@example.com",
          password:              "password",
          password_confirmation: "password"
        }
        User.build(params)
      }

      it "does not save" do
        expect(user).to be_a_new(User)
        expect(user.person.persisted?).to be false
        expect(User.find_by(username: "ohai")).to be_nil
      end

      it "saves successfully" do
        expect(user).to be_valid
        expect(user.save).to be_truthy
        expect(user.person).to be_persisted
        expect(User.find_by(username: "ohai")).to eq(user)
      end
    end

    describe "with invalid parameters" do
      def invalid_params
        {
          username:              "ohai",
          email:                 "ohai@example.com",
          password:              "password",
          password_confirmation: "wrongpasswordz",
          person:                {profile: {first_name: "", last_name: ""}}
        }
      end

      it "raises no error" do
        expect { User.build(invalid_params) }.not_to raise_error
      end

      it "does not save" do
        expect(User.build(invalid_params).save).to be false
      end

      it "does not save a person" do
        expect { User.build(invalid_params) }.not_to change(Person, :count)
      end

      it "does not generate a key" do
        # expect(User).to receive(:generate_keys).exactly(0).times
        u = User.build(invalid_params)
        expect(u.serialized_private_key).to be_blank
      end
    end
  end

  describe "#destroy" do
    def params
      {
        username:              "Ohai",
        email:                 "ohai@example.com",
        password:              "password",
        password_confirmation: "password"
      }
    end

    it "raises error" do
      user = User.build(params)
      expect {
        user.destroy
      }.to raise_error "Never destroy users!"
    end
  end

  describe "send password instructions" do
    it "sends instructions async" do
      user = create(:user)
      assert_enqueued_with(job: Workers::ResetPasswordJob, args: [user]) do
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

      it "saves with current language if blank" do
        I18n.locale = :fr
        user = User.build username: "max", email: "foo@bar.com", password: "password", password_confirmation: "password"
        expect(user.language).to eq("fr")
      end

      it "saves with language what is set" do
        I18n.locale = :fr
        user = User.build(username: "max", email: "foo@bar.com", password: "password",
                          password_confirmation: "password", language: "de")
        expect(user.language).to eq("de")
      end

      it "has a default list of stream languages" do
        expect(alice.stream_languages).to be_empty
      end

      it "has a default list of stream languages" do
        alice.stream_languages.create(language_id: "de")
        expect(alice.stream_languages).not_to be_empty
      end
    end
  end
end
