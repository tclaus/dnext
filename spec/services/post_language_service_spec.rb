# frozen_string_literal: true

require "rails_helper"
describe "PostLanguageService" do
  describe "#detect_post_language" do
    it "sets a language Id for post" do
      cut = PostLanguageService.new
      post = FactoryBot.create(:status_message,
                               author: alice.person,
                               text:   "Sein oder Nichtsein; das ist hier die Frage")
      cut.detect_post_language(post)
      expect(post.language_id).to eq "de"
    end
  end

  describe "#root_post" do
    it "returns a root post if post is a reshare" do
      cut = PostLanguageService.new
      root_post = FactoryBot.create(:status_message, author: alice.person)
      reshare = FactoryBot.create(:reshare, root: root_post, author: eve.person)
      post = cut.root_post(reshare)
      expect(post).to be_instance_of StatusMessage
    end

    it "returns the post if parameter is a post" do
      cut = PostLanguageService.new
      root_post = FactoryBot.create(:status_message, author: alice.person)
      post = cut.root_post(root_post)
      expect(post).to eq root_post
    end
  end
  describe "#language_for_text" do
    it "returns a language struct " do
      cut = PostLanguageService.new
      german_text = "Sein oder Nichtsein; das ist hier die Frage: "\
                    "Obs edler im Gemüt, die Pfeil und Schleudern " \
                    "Des wütenden Geschicks erdulden oder, " \
                    "Sich waffnend gegen eine See von Plagen, "\
                    "Durch Widerstand sie enden? "
      language_id = cut.language_for_text(german_text)
      expect(language_id.language).to eq(:de)
    end
  end
  describe "#remove_urls_from_text" do
    it "removes a easy url" do
      cut = PostLanguageService.new
      cleaned_text = cut.remove_urls_from_text("Look at this: http://excample.com")
      expect(cleaned_text).to eq("Look at this:")
    end

    it "removes a complex url" do
      cut = PostLanguageService.new
      cleaned_text = cut.remove_urls_from_text("Look at this: https://www.tutorialspoint.com/rspec/rspec_matchers.htm "\
                                               "What do you think?")
      expect(cleaned_text).to eq("Look at this:  What do you think?")
    end

    it "removes multiple URLs" do
      cut = PostLanguageService.new
      cleaned_text = cut.remove_urls_from_text("Look at this: "\
                                               "https://google.de is a cool search machine, but others do a good job, "\
                                               "too, like https://duckduckgo.de or bing.de")
      expect(cleaned_text).to eq("Look at this:  is a cool search machine, but others do a good job, too, like  or bing.de")
    end
  end
end
