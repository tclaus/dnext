# frozen_string_literal: true

describe Post, type: :model do
  describe "scopes" do
    describe ".owned_or_visible_by_user" do
      before do
        @you = bob
        @public_post = FactoryBot.create(:status_message, public: true)
        @your_post = FactoryBot.create(:status_message, author: @you.person)
        @post_from_contact = eve.post(:status_message, text: "wooo", to: eve.aspects.where(name: "generic").first)
        @post_from_stranger = FactoryBot.create(:status_message, public: false)
      end

      it "returns post from your contacts" do
        expect(StatusMessage.owned_or_visible_by_user(@you)).to include(@post_from_contact)
      end

      it "returns your posts" do
        expect(StatusMessage.owned_or_visible_by_user(@you)).to include(@your_post)
      end

      it "returns public posts" do
        expect(StatusMessage.owned_or_visible_by_user(@you)).to include(@public_post)
      end

      it "returns public post from your contact" do
        sm = FactoryBot.create(:status_message, author: eve.person, public: true)

        expect(StatusMessage.owned_or_visible_by_user(@you)).to include(sm)
      end

      it "does not return non contacts, non-public post" do
        expect(StatusMessage.owned_or_visible_by_user(@you)).not_to include(@post_from_stranger)
      end

      it "returns the three visible posts" do
        expect(StatusMessage.owned_or_visible_by_user(@you).count(:all)).to eq(3)
      end
    end

    describe ".all_not_blocked_pod" do
      it "returns public and private posts from any pod" do
        post1 = FactoryBot.create(:status_message, author: alice.person, public: true)
        post2 = FactoryBot.create(:status_message, author: bob.person, public: false)
        expect(Post.all_not_blocked_pod.ids).to contain_exactly(post1.id, post2.id)
      end

      it "returns public and private posts from not blocked pods" do
        post2 = FactoryBot.create(:status_message, author: bob.person, public: false)

        blocked_pod = FactoryBot.create(:pod, blocked: true)
        user_from_blocked_pod = FactoryBot.create(:person, pod: blocked_pod)
        FactoryBot.create(:status_message, author: user_from_blocked_pod, public: true)
        expect(Post.all_not_blocked_pod.ids).to contain_exactly(post2.id)
      end
    end

    describe ".all_public" do
      it "includes all public posts" do
        post1 = FactoryBot.create(:status_message, author: alice.person, public: true)
        post2 = FactoryBot.create(:status_message, author: bob.person, public: true)
        post3 = FactoryBot.create(:status_message, author: eve.person, public: true)
        expect(Post.all_public.ids).to contain_exactly(post1.id, post2.id, post3.id)
      end

      it "doesn't include any private posts" do
        FactoryBot.create(:status_message, author: alice.person, public: false)
        FactoryBot.create(:status_message, author: bob.person, public: false)
        FactoryBot.create(:status_message, author: eve.person, public: false)
        expect(Post.all_public.ids).to eq([])
      end

      it "doesn't include any posts tagged as NSFW" do
        post = FactoryBot.create(:status_message, public: true)
        post_nsfw = FactoryBot.create(:status_message, public: true)
        post_nsfw.tag_list.add("nsfw")
        post_nsfw.save_tags
        expect(StatusMessage.all_public_no_nsfw.ids).to eq([post.id])
      end
    end

    describe ".all_local_public" do
      it "includes all public posts from local" do
        post1 = FactoryBot.create(:status_message, author: alice.person, public: true)
        post2 = FactoryBot.create(:status_message, author: bob.person, public: true)
        expect(Post.all_local_public.ids).to contain_exactly(post1.id, post2.id)
      end

      it "doesn't include any posts from other pods" do
        pod = FactoryBot.create(:pod)
        external_person = FactoryBot.create(:person, pod: pod)
        FactoryBot.create(:status_message, author: alice.person, public: true)
        FactoryBot.create(:status_message, author: bob.person, public: true)
        post_from_extern = FactoryBot.create(:status_message, author: external_person, public: true)
        expect(Post.all_local_public.ids).not_to contain_exactly(post_from_extern.id)
      end
    end

    describe ".for_a_stream" do
      it "calls #for_visible_shareable_sql" do
        time = double
        order = double
        expect(Post).to receive(:for_visible_shareable_sql).with(time, order).and_return(Post)
        Post.for_a_stream(time, order)
      end

      it "calls includes_for_a_stream" do
        expect(Post).to receive(:includes_for_a_stream)
        Post.for_a_stream(Time.zone.now, "created_at")
      end

      it "calls excluding_blocks if a user is present" do
        expect(Post).to receive(:excluding_blocks).with(alice).and_return(Post)
        Post.for_a_stream(Time.zone.now, alice)
      end
    end

    describe ".excluding_blocks" do
      before do
        @post = FactoryBot.create(:status_message, author: alice.person)
        @other_post = FactoryBot.create(:status_message, author: eve.person)

        bob.blocks.create(person: alice.person)
      end

      it "does not included blocked users posts" do
        expect(Post.excluding_blocks(Post.all, bob)).not_to include(@post)
      end

      it "includes not blocked users posts" do
        expect(Post.excluding_blocks(Post.all, bob)).to include(@other_post)
      end

      it "returns posts if you dont have any blocks" do
        expect(Post.excluding_blocks(Post.all, alice).count).to eq(2)
      end
    end

    describe ".excluding_hidden_shareables" do
      before do
        @post = FactoryBot.create(:status_message, author: alice.person)
        @other_post = FactoryBot.create(:status_message, author: eve.person)
        bob.toggle_hidden_shareable(@post)
      end

      it "excludes posts the user has hidden" do
        expect(Post.excluding_hidden_shareables(Post.all, bob)).not_to include(@post)
      end

      it "includes posts the user has not hidden" do
        expect(Post.excluding_hidden_shareables(Post.all, bob)).to include(@other_post)
      end
    end

    describe ".excluding_hidden_content" do
      it "calls excluding_blocks and excluding_hidden_shareables" do
        expect(Post).to receive(:excluding_blocks).and_return(Post)
        expect(Post).to receive(:excluding_hidden_shareables)
        Post.excluding_hidden_content(Post.all, bob)
      end
    end

    context "having some posts" do
      before do
        time_interval = 1000
        time_past = 1_000_000
        @posts = (1..5).map do |n|
          aspect_to_post = alice.aspects.where(name: "generic").first
          post = alice.post :status_message, text: "#{alice.username} - #{n}", to: aspect_to_post.id
          post.created_at = (post.created_at - time_past) - time_interval
          post.updated_at = (post.updated_at - time_past) + time_interval
          post.save
          time_interval += 1000
          post
        end
      end

      describe ".for_visible_shareable_sql" do
        it "defaults to 15 posts" do
          chain = double.as_null_object

          allow(Post).to receive(:by_max_time).and_return(chain)
          expect(chain).to receive(:limit).with(15).and_return(Post)
          Post.for_visible_shareable_sql(Time.zone.now + 1, "created_at")
        end

        context "with two posts with the same timestamp" do
          before do
            aspect_id = alice.aspects.where(name: "generic").first.id
            Timecop.freeze Time.zone.now do
              alice.post(:status_message, text: "first", to: aspect_id)
              alice.post(:status_message, text: "second", to: aspect_id)
            end
          end

          it "returns them in reverse creation order" do
            posts = Post.for_visible_shareable_sql(Time.zone.now + 1, "created_at")
            expect(posts.first.text).to eq("second")
            expect(posts.second.text).to eq("first")
            expect(posts.last.text).to eq("alice - 5")
          end
        end
      end
    end

    describe ".subscribed_by" do
      let(:user) { FactoryBot.create(:user) }

      context "when the user has a participation on a post" do
        let(:post) { FactoryBot.create(:status_message_with_participations, participants: [user]) }

        it "includes the post to the result set" do
          expect(Post.subscribed_by(user)).to eq([post])
        end
      end

      context "when the user doens't have a participation on a post" do
        before do
          FactoryBot.create(:status_message)
        end

        it "returns empty result set" do
          expect(Post.subscribed_by(user)).to be_empty
        end
      end
    end

    describe ".reshared_by" do
      let(:person) { FactoryBot.create(:person) }

      context "when the person has a reshare for a post" do
        let(:post) { FactoryBot.create(:reshare, author: person).root }

        it "includes the post to the result set" do
          expect(Post.reshared_by(person)).to eq([post])
        end
      end

      context "when the person has no reshare for a post" do
        before do
          FactoryBot.create(:status_message)
        end

        it "returns empty result set" do
          expect(Post.reshared_by(person)).to be_empty
        end
      end
    end
  end

  describe "validations" do
    it "validates uniqueness of guid and does not throw a db error" do
      message = FactoryBot.create(:status_message)
      expect(FactoryBot.build(:status_message, guid: message.guid)).not_to be_valid
    end
  end

  describe "post_type" do
    it "returns the class constant" do
      status_message = FactoryBot.create(:status_message)
      expect(status_message.post_type).to eq("StatusMessage")
    end
  end

  describe "deletion" do
    it "deletes a posts comments on delete" do
      post = FactoryBot.create(:status_message, author: alice.person)
      alice.comment!(post, "hey")
      post.destroy
      expect(Post.where(id: post.id).empty?).to be(true)
      expect(Comment.where(text: "hey").empty?).to be(true)
    end
  end

  describe ".diaspora_initialize" do
    it "takes provider_display_name" do
      sm = FactoryBot.create(:status_message, provider_display_name: "mobile")
      expect(StatusMessage.diaspora_initialize(sm.attributes.merge(author: bob.person))
        .provider_display_name).to eq("mobile")
    end
  end

  describe "#subscribers" do
    let(:user) { FactoryBot.create(:user_with_aspect) }

    before do
      user.share_with(alice.person, user.aspects.first)
    end

    context "private" do
      it "returns the people contained in the aspects the post appears in" do
        post = user.post(:status_message, text: "hello", to: user.aspects.first.id)

        expect(post.subscribers).to eq([alice.person])
      end

      it "returns empty if posted to an empty aspect" do
        empty_aspect = user.aspects.create(name: "empty")

        post = user.post(:status_message, text: "hello", to: empty_aspect.id)

        expect(post.subscribers).to eq([])
      end
    end

    context "public" do
      let(:post) { user.post(:status_message, text: "hello", public: true) }

      it "returns the author to ensure local delivery" do
        lonely_user = FactoryBot.create(:user)
        lonely_post = lonely_user.post(:status_message, text: "anyone?", public: true)
        expect(lonely_post.subscribers).to contain_exactly(lonely_user.person)
      end

      it "returns all a users contacts if the post is public" do
        second_aspect = user.aspects.create(name: "winners")
        user.share_with(bob.person, second_aspect)

        expect(post.subscribers).to contain_exactly(alice.person, bob.person, user.person)
      end

      it "adds resharers to subscribers" do
        FactoryBot.create(:reshare, root: post, author: eve.person)

        expect(post.subscribers).to contain_exactly(alice.person, eve.person, user.person)
      end

      it "adds participants to subscribers" do
        eve.participate!(post)

        expect(post.subscribers).to contain_exactly(alice.person, eve.person, user.person)
      end
    end
  end

  describe "Likeable#update_likes_counter" do
    before do
      @post = bob.post(:status_message, text: "hello", public: true)
      bob.like!(@post)
    end

    it "does not update updated_at" do
      old_time = Time.zone.now - 100
      Post.where(id: @post.id).update_all(updated_at: old_time)
      expect(@post.reload.updated_at.to_i).to eq(old_time.to_i)
      @post.update_likes_counter
      expect(@post.reload.updated_at.to_i).to eq(old_time.to_i)
    end
  end

  describe "#receive" do
    it "creates a share visibility for the user" do
      user_ids = [alice.id, eve.id]
      post = FactoryBot.create(:status_message, author: bob.person)
      expect(ShareVisibility).to receive(:batch_import).with(user_ids, post)
      post.receive(user_ids)
    end

    it "does nothing for public post" do
      post = FactoryBot.create(:status_message, author: bob.person, public: true)
      expect(ShareVisibility).not_to receive(:batch_import)
      post.receive([alice.id])
    end

    it "does nothing if no recipients provided" do
      post = FactoryBot.create(:status_message, author: bob.person)
      expect(ShareVisibility).not_to receive(:batch_import)
      post.receive([])
    end
  end

  describe "#reshares_count" do
    before do
      @post = alice.post(:status_message, text: "hello", public: true)
      expect(@post.reshares.size).to eq(0)
    end

    describe "when post has not been reshared" do
      it "returns zero" do
        expect(@post.reshares_count).to eq(0)
      end
    end

    describe "when post has been reshared exactly 1 time" do
      before do
        expect(@post.reshares.size).to eq(0)
        @reshare = FactoryBot.create(:reshare, root: @post)
        @post.reload
        expect(@post.reshares.size).to eq(1)
      end

      it "returns 1" do
        expect(@post.reshares_count).to eq(1)
      end
    end

    describe "when post has been reshared more than once" do
      before do
        expect(@post.reshares.size).to eq(0)
        FactoryBot.create(:reshare, root: @post)
        FactoryBot.create(:reshare, root: @post)
        FactoryBot.create(:reshare, root: @post)
        @post.reload
        expect(@post.reshares.size).to eq(3)
      end

      it "returns the number of reshares" do
        expect(@post.reshares_count).to eq(3)
      end
    end
  end

  describe "#after_create" do
    it "sets #interacted_at" do
      post = FactoryBot.create(:status_message)
      expect(post.interacted_at).not_to be_blank
    end
  end

  describe "#before_destroy" do
    it "removes root_guid from reshares" do
      post = FactoryBot.create(:status_message, author: alice.person, public: true)
      reshare = FactoryBot.create(:reshare, author: bob.person, root: post)
      post.destroy!
      expect(reshare.reload.root_guid).to be_nil
    end
  end
end
