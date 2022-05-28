# frozen_string_literal: true

require "rails_helper"

RSpec.describe PostsHelper, type: :helper do
  describe "#post_page_title" do
    before do
      @sm = FactoryBot.create(:status_message)
    end

    context "with posts with text" do
      it "delegates to message.title" do
        message = double
        expect(message).to receive(:title)
        post = double(message: message)
        post_page_title(post)
      end
    end

    context "with a reshare" do
      it "returns 'Reshare by...'" do
        reshare = FactoryBot.create(:reshare, author: alice.person)
        expect(post_page_title(reshare)).to eq I18n.t("posts.show.reshare_by", author: reshare.author_name)
      end
    end
  end
end
