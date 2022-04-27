require "rspec"

describe PostPresenter do
  let(:status_message) { FactoryBot.create(:status_message, public: true) }
  let(:presenter) { PostPresenter.new(:status_message, bob) }

  it "takes a post and an optional user" do
    expect(presenter).not_to be_nil
  end
  context "post with interactions" do
    before do
      bob.like!(:status_message)
      # TODO: Test for Reshare when implemented
    end

    it "includes the users like" do
      expect(presenter.send(:own_like)).to be_present
    end
  end
end
