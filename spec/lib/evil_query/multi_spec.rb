# frozen_string_literal: true

require Rails.root.join("spec/shared_behaviours/stream")

describe EvilQuery::Multi do
  before do
    @evil_query_multi = EvilQuery::Multi.new(alice)
  end

  describe "posts!" do
    it "should call community_spotlight_posts relation" do
      expect(@evil_query_multi).to receive(:community_spotlight_posts!).and_return(Post.all)
      @evil_query_multi.posts
    end

    it "should call exclude_hidden_content" do
      expect(@evil_query_multi).to receive(:exclude_hidden_content).and_return(Post.all)
      @evil_query_multi.posts
    end

    it "should call aspects" do
      expect(@evil_query_multi).to receive(:aspects).and_return(Post.all)
      @evil_query_multi.posts
    end

    it "should call visible_shareable" do
      expect(@evil_query_multi).to receive(:visible_shareable).and_return(Post.all)
      @evil_query_multi.posts
    end

    it "should call followed_tags" do
      expect(@evil_query_multi).to receive(:followed_tags).and_return(Post.all)
      @evil_query_multi.posts
    end

    it "should call mentioned_posts" do
      expect(@evil_query_multi).to receive(:mentioned_posts).and_return(Post.all)
      @evil_query_multi.posts
    end
  end

  describe "community_spotlight_posts!" do
    it "returns a relation with community posts" do
      Role.add_spotlight(alice.person)
      spotlight_role = FactoryBot.create(:status_message, author: alice.person)
      expect(@evil_query_multi.community_spotlight_posts!.ids).to match_array([spotlight_role.id])
    end
  end
end
