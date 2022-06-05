# frozen_string_literal: true

require Rails.root.join("spec/shared_behaviours/stream")

describe Stream::Tag do
  before do
    @stream = Stream::Tag.new(alice, "linux")
  end

  describe "shared behaviors" do
    it_behaves_like "it is a stream"
  end

  it "down-cases tags before processing" do
    stream = Stream::Tag.new(alice, "#LINUX")
    expect(stream.tag_names).to match("linux")
  end

  it "returns posts in any language" do
    english_user = FactoryBot.create(:user)
    english_user.stream_languages.create(language_id: "en")
    stream = Stream::Tag.new(english_user, "linux")
    post_de = FactoryBot.create(:status_message, author: alice.person, public: true)
    post_de.text = "#linux ist toll"
    post_de.language_id = "de"
    post_de.save

    post_en = FactoryBot.create(:status_message, author: bob.person, public: true)
    post_en.text = "#linux is cool"
    post_en.language_id = "en"
    post_en.save
    localized_posts = stream.posts
    expect(localized_posts.ids).to match_array([post_en.id, post_de.id])
  end

  it "returns people filtered by blocked persons" do
    user = FactoryBot.create(:user)
    blocked_user = FactoryBot.create(:user)
    user.blocks.create!(person: blocked_user.person)

    stream = Stream::Tag.new(user, "linux")
    post1 = FactoryBot.create(:status_message, author: blocked_user.person, public: true)
    post1.text = "#linux"
    post1.save
    expect(stream.posts.ids).to match_array([])
  end

  describe "returns posts filtered by blocked or hidden content" do
    it "blocks hidden shareables" do
      user = FactoryBot.create(:user)
      stream = Stream::Tag.new(user, "linux")
      post1 = FactoryBot.create(:status_message, author: alice.person, public: true)
      post1.text = "#linux"
      post1.save
      hidden_post = FactoryBot.create(:status_message, author: bob.person, public: true)
      hidden_post.text = "#linux"
      hidden_post.save
      user.toggle_hidden_shareable(hidden_post)
      expect(stream.posts.ids).to match_array([post1.id])
    end
  end
end
