require "rspec"

describe PersonPresenter do
  let(:profile_user) {
    FactoryBot.create(:user_with_aspect,
                      profile: FactoryBot.create(:profile_with_image_url))
  }
  let(:person) { profile_user.person }

  let(:mutual_contact) {
    FactoryBot.create(:contact, user: current_user, person: person, sharing: true, receiving: true)
  }
  let(:receiving_contact) {
    FactoryBot.create(:contact, user: current_user, person: person, sharing: false, receiving: true)
  }
  let(:sharing_contact) {
    FactoryBot.create(:contact, user: current_user, person: person, sharing: true, receiving: false)
  }
  let(:non_contact) {
    FactoryBot.create(:contact, user: current_user, person: person, sharing: false, receiving: false)
  }

  after do
    # Do nothing
  end
  describe "#full_hash" do
    let(:current_user) { FactoryBot.create(:user) }

    before do
      @person_presenter = PersonPresenter.new(person, current_user)
    end

    it "should not show photos if none" do
      expect(@person_presenter.show_photos?).to be_falsey
    end

    it "should show photos if present" do
      current_user.photos.add(FactoryBot.create(:photo))
      expect(@person_presenter.show_photos?).to be_truthy
    end

    it "should return true for own profile" do
      expect(@person_presenter.current_user).to receive(:person).and_return(current_user)
      expect(@person_presenter.own_profile?).to be_falsey
    end

    it "should test for own profile" do
      expect(@person_presenter.own_profile?).to be_falsey
    end

    context "relationship" do
      it "is mutual?" do
        allow(current_user).to receive(:contact_for) { mutual_contact }
        expect(@person_presenter.relationship).to be(:mutual)
      end

      it "is receiving?" do
        allow(current_user).to receive(:contact_for) { receiving_contact }
        expect(@person_presenter.relationship).to be(:receiving)
      end

      it "is sharing?" do
        allow(current_user).to receive(:contact_for) { sharing_contact }
        expect(@person_presenter.relationship).to be(:sharing)
      end

      it "isn't sharing?" do
        allow(current_user).to receive(:contact_for) { non_contact }
        expect(@person_presenter.relationship).to be(:not_sharing)
      end
    end
  end
end
