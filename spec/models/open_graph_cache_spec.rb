# frozen_string_literal: true

#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

describe OpenGraphCache do
  describe "fetch_and_save_opengraph_data!" do
    context "with an unsecure video url" do
      it "doesn't save the video url" do
        expect(OpenGraphReader).to receive(:fetch!).with(URI.parse("https://example.com/article/123")).and_return(
          double(
            og: double(
              description: "This is the article lead",
              image:       double(url: "https://example.com/image/123.jpg"),
              title:       "Some article",
              type:        "article",
              url:         "https://example.com/acticle/123-seo-foo",
              video:       double(secure_url: "https://example.com/videos/123.html"),
              locale:      double(content: "en")
            )
          )
        )
        ogc = OpenGraphCache.new(url: "https://example.com/article/123")
        ogc.fetch_and_save_opengraph_data!

        expect(ogc.description).to eq("This is the article lead")
        expect(ogc.image).to eq("https://example.com/image/123.jpg")
        expect(ogc.title).to eq("Some article")
        expect(ogc.ob_type).to eq("article")
        expect(ogc.url).to eq("https://example.com/acticle/123-seo-foo")
        expect(ogc.video_url).to be_nil
      end
    end

    context "with a secure video url" do
      it "saves the video url" do
        expect(OpenGraphReader).to receive(:fetch!).with(URI.parse("https://example.com/article/123")).and_return(
          double(
            og: double(
              description: "This is the article lead",
              image:       double(url: "https://example.com/image/123.jpg"),
              title:       "Some article",
              type:        "article",
              url:         "https://example.com/acticle/123-seo-foo",
              video:       double(secure_url: "https://bandcamp.com/EmbeddedPlayer/v=2/track=12/size=small"),
              locale:      double(content: "en")
            )
          )
        )
        ogc = OpenGraphCache.new(url: "https://example.com/article/123")
        ogc.fetch_and_save_opengraph_data!

        expect(ogc.description).to eq("This is the article lead")
        expect(ogc.image).to eq("https://example.com/image/123.jpg")
        expect(ogc.title).to eq("Some article")
        expect(ogc.ob_type).to eq("article")
        expect(ogc.url).to eq("https://example.com/acticle/123-seo-foo")
        expect(ogc.video_url).to eq("https://bandcamp.com/EmbeddedPlayer/v=2/track=12/size=small")
      end
    end

    context "with a mixed case hostname" do
      it "downcases the hostname" do
        stub_request(:head, "http:///wetter.com")
          .with(headers: {
                  "Accept"     => "text/html",
                  "User-Agent" => "OpenGraphReader/0.7.2 (+https://github.com/jhass/open_graph_reader)"
                })
          .to_return(status: 200, body: "", headers:
            {"Set-Cookie" => "Dabgroup=A;path=/;Expires=Thu, 23 May 2019 16:12:01 GMT;httpOnly"})

        ogc = OpenGraphCache.new(url: "Wetter.com")
        expect {
          ogc.fetch_and_save_opengraph_data!
        }.not_to raise_error
      end
    end

    context "with language detection" do
      it "reads the language from provided data" do
        expect(OpenGraphReader).to receive(:fetch!).with(URI.parse("https://example.com/article/123")).and_return(
          double(
            og: double(
              description: "This is the article lead",
              image:       double(url: "https://example.com/image/123.jpg"),
              title:       "Some article",
              type:        "article",
              url:         "https://example.com/acticle/123-seo-foo",
              video:       double(secure_url: "https://example.com/videos/123.html"),
              locale:      double(content: "en")
            )
          )
        )
        ogc = OpenGraphCache.new(url: "https://example.com/article/123")
        ogc.fetch_and_save_opengraph_data!

        expect(ogc.locale).to eq "en"
      end

      it "reads the language" do
        expect(OpenGraphReader).to receive(:fetch!).with(URI.parse("https://example.com/article/123")).and_return(
          double(
            og: double(
              description: "This is the article lead",
              image:       double(url: "https://example.com/image/123.jpg"),
              title:       "Some article",
              type:        "article",
              url:         "https://example.com/acticle/123-seo-foo",
              video:       double(secure_url: "https://example.com/videos/123.html"),
              locale:      double(content: "en")
            )
          )
        )
        ogc = OpenGraphCache.new(url: "https://example.com/article/123")
        ogc.fetch_and_save_opengraph_data!

        expect {
          ogc.detect_language_by_description
        }
      end
    end
  end
end
