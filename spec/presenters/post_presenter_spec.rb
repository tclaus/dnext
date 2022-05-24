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

  before do
    @post = FactoryBot.create(:status_message, public: true)
    @post_presenter = PostPresenter.new(@post, bob)
    @reshare = FactoryBot.create(:reshare)
    @reshare_presenter = PostPresenter.new(@reshare, bob)
  end

  describe "user_can_reshare?" do
    it "returns false if the post is not pubic" do
      @post.public = false
      expect(@post_presenter.user_can_reshare?).to be false
    end

    it "returns false if the posts author is current user" do
      @post.author = bob.person
      expect(@post_presenter.user_can_reshare?).to be false
    end

    it "returns false if a reshare has no root" do
      @reshare.root = nil
      expect(@reshare_presenter.user_can_reshare?).to be false
    end

    it "returns false if a reshare root post author is current user" do
      @reshare.root.author = bob.person
      expect(@reshare_presenter.user_can_reshare?).to be false
    end

    it "returns false already reshared by current_user" do
      @reshare.author = alice.person
      @reshare.save
      reshared_post = @reshare.root
      reshared_presenter = PostPresenter.new(reshared_post, alice)
      expect(reshared_presenter.user_can_reshare?).to be false
    end

    it "returns true for post" do
      expect(@post_presenter.user_can_reshare?).to be true
    end

    it "returns true for reshare" do
      expect(@reshare_presenter.user_can_reshare?).to be true
    end
  end
end
