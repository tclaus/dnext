# frozen_string_literal: true

require "shared_behaviours/shareable"
require "shared_behaviours/mentioned_container"
require "shared_behaviours/reference_target"
require "shared_behaviours/reference_source"
require "shared_behaviours/taggable"

describe StatusMessage, type: :model do
  include PeopleHelper

  let!(:user) { alice }
  let!(:aspect) { user.aspects.first }
  let(:status) { build(:status_message) }

  it_behaves_like "a shareable" do
    let(:object) { status }
  end

  describe "scopes" do
    describe ".where_person_is_mentioned" do
      it "returns status messages where the given person is mentioned" do
        @bob = bob.person
        @test_string = "@{Daniel; #{@bob.diaspora_handle}} can mention people like Raph"
        post1 = FactoryBot.create(:status_message, text: @test_string, public: true)
        post2 = FactoryBot.create(:status_message, text: @test_string, public: true)
        FactoryBot.create(:status_message, text: @test_string)
        FactoryBot.create(:status_message, public: true)

        expect(StatusMessage.where_person_is_mentioned(@bob).ids).to contain_exactly(post1.id, post2.id)
      end
    end

    context "tag_streams" do
      before do
        @status_message1 = FactoryBot.create(:status_message, text: "#hashtag", public: true)
        @status_message2 = FactoryBot.create(:status_message, text: "#hashtag")
        @status_message3 = FactoryBot.create(:status_message, text: "hashtags are #awesome", public: true)
        @status_message4 = FactoryBot.create(:status_message, text: "hashtags are #awesome")

        @tag_id = ActsAsTaggableOn::Tag.where(name: "hashtag").first.id
      end

      describe ".tag_steam" do
        it "returns status messages tagged with the tag" do
          tag_stream = StatusMessage.send(:all_tag_stream, [@tag_id])
          expect(tag_stream).to include @status_message1
          expect(tag_stream).to include @status_message2
        end
      end

      describe ".public_any_tag_stream" do
        it "returns public status messages tagged with the tag" do
          expect(StatusMessage.public_any_tag_stream([@tag_id])).to eq([@status_message1])
        end

        it "returns a post with two tags only once" do
          status_message = FactoryBot.create(:status_message, text: "#hashtag #test", public: true)
          test_tag_id = ActsAsTaggableOn::Tag.where(name: "test").first.id

          expect(StatusMessage.public_any_tag_stream([@tag_id, test_tag_id]))
            .to contain_exactly(@status_message1, status_message)
        end
      end

      describe ".user_tag_stream" do
        it "returns tag stream thats owned or visible by" do
          relation = double
          expect(StatusMessage).to receive(:owned_or_visible_by_user).with(bob).and_return(relation)
          expect(relation).to receive(:any_tag_stream).with([@tag_id])

          StatusMessage.any_user_tag_stream(bob, [@tag_id])
        end
      end
    end
  end

  describe ".guids_for_author" do
    it "returns an array of the status_message guids" do
      status_message1 = FactoryBot.create(:status_message, author: alice.person)
      FactoryBot.create(:status_message, author: bob.person)
      guids = StatusMessage.guids_for_author(alice.person)
      expect(guids).to eq([status_message1.guid])
    end
  end

  describe ".before_validation" do
    it "calls build_tags" do
      # expect(status).to receive(:build_tags)
      status.save
    end
  end

  describe ".before_create" do
    it "calls build_tags" do
      expect(status).to receive(:build_tags)
      status.save
    end
  end

  context "emptiness" do
    it "needs either a message or at least one photo" do
      post = user.build_post(:status_message, text: nil)
      expect(post).not_to be_valid

      post.text = ""
      expect(post).not_to be_valid

      post.text = "wales"
      expect(post).to be_valid
      post.text = nil

      photo = user.build_post(:photo, user_file: uploaded_photo, to: aspect.id)
      photo.save!

      post.photos << photo
      expect(post).to be_valid
      expect(post.message.to_s).to be_empty
      expect(post.text).to be_nil
      expect(post.nsfw).to be_falsey
      expect(post.errors.full_messages).to eq([])
    end

    it "also checks for content when author is remote" do
      post = FactoryBot.build(:status_message, text: nil)
      expect(post).not_to be_valid
    end
  end

  it "is postable through the user" do
    message = "Users do things"
    status = user.post(:status_message, text: message, to: aspect.id)
    db_status = StatusMessage.find(status.id)
    expect(db_status.text).to eq(message)
  end

  it "requires status messages not be more than 65535 characters long" do
    message = "a" * (65_535 + 1)
    status_message = FactoryBot.build(:status_message, text: message)
    expect(status_message).not_to be_valid
  end

  it_behaves_like "it is mentions container"

  describe "#people_allowed_to_be_mentioned" do
    it "returns only aspects members for private posts" do
      sm = FactoryBot.build(:status_message_in_aspect)
      sm.author.owner.share_with(alice.person, sm.author.owner.aspects.first)
      sm.author.owner.share_with(eve.person, sm.author.owner.aspects.first)
      sm.save!

      expect(sm.people_allowed_to_be_mentioned).to contain_exactly(alice.person_id, eve.person_id)
    end

    it "returns :all for public posts" do
      expect(FactoryBot.create(:status_message, public: true).people_allowed_to_be_mentioned).to eq(:all)
    end
  end

  it_behaves_like "a reference source"
  it_behaves_like "a reference target"

  describe "#nsfw" do
    it "returns MatchObject (true) if the post contains #nsfw (however capitalised)" do
      status = FactoryBot.build(:status_message, text: "This message is #nSFw")
      expect(status.nsfw).to be_truthy
    end

    it "returns nil (false) if the post does not contain #nsfw" do
      status = FactoryBot.build(:status_message, text: "This message is #sFW")
      expect(status.nsfw).to be false
    end
  end

  describe "#comment_email_subject" do
    it "delegates to message.title if the post have a text" do
      expect(status.comment_email_subject).to eq(status.message.title)
    end

    it "includes the photos count if there are photos without text" do
      photo = FactoryBot.build(:photo, public: true)
      status = FactoryBot.build(:status_message, author: photo.author, text: nil, photos: [photo], public: true)
      expect(status.comment_email_subject).to eq(I18n.t("posts.show.photos_by", count: 1, author: status.author_name))
    end
  end

  describe "tags" do
    it_behaves_like "it is taggable" do
      let(:object) { build(:status_message) }
    end

    it "associates different-case tags to the same tag entry" do
      expect(ActsAsTaggableOn.force_lowercase).to eq(true)

      msg_lc = FactoryBot.build(:status_message, text: "#newhere")
      msg_uc = FactoryBot.build(:status_message, text: "#NewHere")
      msg_cp = FactoryBot.build(:status_message, text: "#NEWHERE")

      msg_lc.save
      msg_uc.save
      msg_cp.save

      tag_array = msg_lc.tags
      expect(msg_uc.tags).to match_array(tag_array)
      expect(msg_cp.tags).to match_array(tag_array)
    end

    it "requires tag name not be more than 255 characters long" do
      message = "##{'a' * (255 + 1)}"
      status_message = FactoryBot.build(:status_message, text: message)
      expect(status_message).not_to be_valid
    end
  end

  describe "oembed" do
    let(:youtube_url) { "https://www.youtube.com/watch?v=3PtFwlKfvHI" }
    let(:message_text) { "#{youtube_url} is so cool. so is this link -> https://joindiaspora.com" }
    let(:status_message) { FactoryBot.build(:status_message, text: message_text) }

    it "queues a GatherOembedData if it includes a link" do
      status_message
      expect(Workers::GatherOEmbedData).to receive(:perform_later).with(kind_of(Integer), instance_of(String))
      status_message.save
    end

    describe "#contains_oembed_url_in_text?" do
      it "returns the oembed urls found in the raw message" do
        expect(status_message.contains_oembed_url_in_text?).not_to be_nil
        expect(status_message.oembed_url).to eq(youtube_url)
      end
    end
  end

  describe "opengraph" do
    let(:ninegag_url) { "https://9gag.com/gag/a1AMW16" }
    let(:youtube_url) { "https://www.youtube.com/watch?v=3PtFwlKfvHI" }
    let(:message_text) { "#{ninegag_url} is so cool. so is this link -> https://joindiaspora.com" }
    let(:oemessage_text) { "#{youtube_url} is so cool. so is this link -> https://joindiaspora.com" }
    let(:status_message) { build(:status_message, text: message_text) }

    it "queues a GatherOpenGraphData if it includes a link" do
      status_message
      expect(Workers::GatherOpenGraphData).to receive(:perform_later).with(kind_of(Integer), instance_of(String))
      status_message.save
    end

    describe "#contains_open_graph_url_in_text?" do
      it "returns the opengraph urls found in the raw message" do
        expect(status_message.contains_open_graph_url_in_text?).not_to be_nil
        expect(status_message.open_graph_url).to eq(ninegag_url)
      end

      it "returns nil if the link is from trusted oembed provider" do
        status_message = FactoryBot.build(:status_message, text: oemessage_text)
        expect(status_message.contains_open_graph_url_in_text?).to be_nil
        expect(status_message.open_graph_url).to be_nil
      end
    end
  end

  describe "poll" do
    it "destroys the poll (with all answers and participations) when the status message is destroyed" do
      poll = FactoryBot.create(:poll_participation).poll
      status_message = poll.status_message

      poll_id = poll.id
      poll_answers = poll.poll_answers.map(&:id)
      poll_participations = poll.poll_participations.map(&:id)

      status_message.destroy

      expect(Poll.where(id: poll_id)).not_to exist
      poll_answers.each {|id| expect(PollAnswer.where(id: id)).not_to exist }
      poll_participations.each {|id| expect(PollParticipation.where(id: id)).not_to exist }
    end
  end

  describe "validation" do
    let(:status_message) { build(:status_message, text: @message_text) }

    it "is not valid if the author is missing" do
      status_message.author = nil
      expect(status_message).not_to be_valid
    end
  end

  describe "#coordinates" do
    let(:status_message) { build(:status_message, text: @message_text) }

    context "with location" do
      let(:location) { build(:location) }

      it "delivers address and coordinates" do
        status_message.location = location
        expect(status_message.post_location).to include(address: location.address, lat: location.lat, lng: location.lng)
      end
    end

    context "without location" do
      it "delivers empty address and coordinates" do
        expect(status_message.post_location[:address]).to be_nil
        expect(status_message.post_location[:lat]).to be_nil
        expect(status_message.post_location[:lng]).to be_nil
      end
    end
  end

  describe "#receive" do
    let(:post) { FactoryBot.create(:status_message, author: alice.person) }

    it "receives attached photos" do
      photo = FactoryBot.create(:photo, status_message: post, author: alice.person)

      post.receive([bob.id])

      expect(ShareVisibility.where(user_id: bob.id, shareable_id: post.id, shareable_type: "Post").count).to eq(1)
      expect(ShareVisibility.where(user_id: bob.id, shareable_id: photo.id, shareable_type: "Photo").count).to eq(1)
    end

    it "works without attached photos" do
      post.receive([bob.id])

      expect(ShareVisibility.where(user_id: bob.id, shareable_id: post.id, shareable_type: "Post").count).to eq(1)
    end

    it "works with already received attached photos" do
      photo = FactoryBot.create(:photo, status_message: post, author: alice.person)

      photo.receive([bob.id])
      post.receive([bob.id])

      expect(ShareVisibility.where(user_id: bob.id, shareable_id: post.id, shareable_type: "Post").count).to eq(1)
      expect(ShareVisibility.where(user_id: bob.id, shareable_id: photo.id, shareable_type: "Photo").count).to eq(1)
    end
  end
end
