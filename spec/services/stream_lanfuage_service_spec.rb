# frozen_string_literal: true

require "rails_helper"

describe StreamLanguageService do
  describe "language_for_stream" do
    # rubocop:disable Rails/I18nLocaleAssignment
    context "when user has no stream language set" do
      context "and the current language is a major language" do
        it "returns the current language" do
          I18n.locale = :de
          alice.stream_languages.clear
          cut = StreamLanguageService.new(alice)
          expect(cut.language_for_stream).to match_array(["de"])
        end
      end
      context "and current language is a rarely use one" do
        it "returns the current and fallback language " do
          I18n.locale = :uk
          alice.stream_languages.clear
          cut = StreamLanguageService.new(alice)
          expect(cut.language_for_stream).to match_array(%w[uk en])
        end
      end
    end
    context "when the user has set a language" do
      it "returns the user selected language" do
        I18n.locale = :en
        alice.stream_languages.clear
        alice.stream_languages.create(language_id: "uk")
        cut = StreamLanguageService.new(alice)
        expect(cut.language_for_stream).to match_array("uk")
      end
    end
    # rubocop:enable Rails/I18nLocaleAssignment
  end
end
