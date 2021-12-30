# frozen_string_literal: true

module Diaspora
  module Markdownify
    class Html < Redcarpet::Render::HTML
      include ActionView::Helpers::TextHelper

      # @param [String] link
      # @param [String] type
      def autolink(link, type)
        Twitter::TwitterText::Autolink.auto_link_urls(
          link,
          url_target: "_blank",
          link_attribute_block: lambda { |_, attr| attr[:rel] += " noopener noreferrer" }
        )
      end
    end
  end
end
