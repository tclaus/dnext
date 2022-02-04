require "rails_helper"

describe User, type: :model do
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
end
