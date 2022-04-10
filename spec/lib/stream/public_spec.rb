# frozen_string_literal: true

require Rails.root.join("spec/shared_behaviours/stream")

describe Stream::Public do
  before do
    @stream = Stream::Public.new(alice)
  end

  describe "shared behaviors" do
    it_should_behave_like "it is a stream"
  end

  describe "#posts" do
    it "calls Post#all_public" do
      expect(Post).to receive(:all_public)
      expect(Post).to receive(:for_a_stream)
      expect(@stream).to receive(:posts_by_language)
      @stream.posts
    end

    it "calls for_a_stream when user is set" do
      expect(Post).to receive(:for_a_stream)
      expect(@stream).to receive(:posts_by_language)
      @stream.posts
    end

    it "returns no posts with a defined language" do
      english_user = FactoryBot.create(:user)
      english_user.stream_languages.create(language_id: "en")
      stream = Stream::Public.new(english_user)
      post_de = FactoryBot.create(:status_message, author: alice.person, public: true)
      post_de.language_id = "en"
      post_de.save

      post_no_language_set = FactoryBot.create(:status_message, author: bob.person, public: true)
      post_no_language_set.language_id = nil
      post_no_language_set.save
      localized_posts = stream.posts
      expect(localized_posts.ids).to match_array([post_de.id, post_no_language_set.id])
    end

    it "returns posts filtered by language" do
      english_user = FactoryBot.create(:user)
      english_user.stream_languages.create(language_id: "en")
      stream = Stream::Public.new(english_user)
      post_de = FactoryBot.create(:status_message, author: alice.person, public: true)
      post_de.language_id = "de"
      post_de.save

      post_en = FactoryBot.create(:status_message, author: bob.person, public: true)
      post_en.language_id = "en"
      post_en.save
      localized_posts = stream.posts
      expect(localized_posts.ids).to match_array([post_en.id])
      expect(localized_posts.ids).not_to match_array([post_de.id])
    end

    it "returns posts with by browser settings" do
      user = FactoryBot.create(:user)
      stream = Stream::Public.new(user)
      post1 = FactoryBot.create(:status_message, author: alice.person, public: true)
      post1.language_id = "en"
      post1.save

      post2 = FactoryBot.create(:status_message, author: bob.person, public: true)
      post2.language_id = "dn"
      post2.save

      localized_posts = stream.posts
      expect(localized_posts.ids).to match_array([post1.id])
    end

    describe "returns posts filtered by blocked or hidden content" do
      it "blocks hidden shareables" do
        user = FactoryBot.create(:user)
        stream = Stream::Public.new(user)
        post1 = FactoryBot.create(:status_message, author: alice.person, public: true)

        hidden_post = FactoryBot.create(:status_message, author: bob.person, public: true)

        user.toggle_hidden_shareable(hidden_post)
        expect(stream.posts.ids).to match_array([post1.id])
      end
    end
  end
end
