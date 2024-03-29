# frozen_string_literal: true

shared_examples_for "a reference source" do
  let!(:source) { FactoryBot.create(described_class.to_s.underscore.to_sym) }
  let!(:reference) { FactoryBot.create(:reference, source: source) }

  describe "references" do
    it "returns the references" do
      expect(source.references).to match_array([reference])
    end

    it "destroys the reference when the source is destroyed" do
      source.destroy
      expect(Reference.where(id: reference.id)).not_to exist
    end
  end

  describe "#create_references" do
    it "creates a reference for every referenced post after create" do
      target1 = FactoryBot.create(:status_message)
      target2 = FactoryBot.create(:status_message)
      text = "Have a look at [this post](diaspora://#{target1.diaspora_handle}/post/#{target1.guid}) and " \
             "this one too diaspora://#{target2.diaspora_handle}/post/#{target2.guid}."

      post = FactoryBot.build(described_class.to_s.underscore.to_sym, text: text)
      post.save

      expect(post.references.map(&:target).map(&:guid)).to match_array([target1, target2].map(&:guid))
    end

    it "ignores a reference with a unknown guid" do
      text = "Try this: `diaspora://unknown@localhost:3000/post/thislookslikeavalidguid123456789`"

      post = FactoryBot.build(described_class.to_s.underscore.to_sym, text: text)
      post.save

      expect(post.references).to be_empty
    end

    it "ignores a reference with an invalid entity type" do
      target = FactoryBot.create(:status_message)

      text = "Try this: `diaspora://#{target.diaspora_handle}/posts/#{target.guid}`"

      post = FactoryBot.build(described_class.to_s.underscore.to_sym, text: text)
      post.save

      expect(post.references).to be_empty
    end

    it "only creates one reference, even when it is referenced twice" do
      target = FactoryBot.create(:status_message)
      text = "Have a look at [this post](diaspora://#{target.diaspora_handle}/post/#{target.guid}) and " \
             "this one too diaspora://#{target.diaspora_handle}/post/#{target.guid}."

      post = FactoryBot.build(described_class.to_s.underscore.to_sym, text: text)
      post.save

      expect(post.references.map(&:target).map(&:guid)).to match_array([target.guid])
    end

    it "only creates references, when the author of the known entity matches" do
      target1 = FactoryBot.create(:status_message)
      target2 = FactoryBot.create(:status_message)
      text = "Have a look at [this post](diaspora://#{target1.diaspora_handle}/post/#{target1.guid}) and " \
             "this one too diaspora://#{target1.diaspora_handle}/post/#{target2.guid}."

      post = FactoryBot.build(described_class.to_s.underscore.to_sym, text: text)
      post.save

      expect(post.references.map(&:target).map(&:guid)).to match_array([target1.guid])
    end
  end
end
