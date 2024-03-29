# frozen_string_literal: true

module OEmbedHelper
  # @param [OEmbedCache] cache
  def o_embed_html(cache)
    data = cache.data
    data = {} if data.blank?
    title = data.fetch("title", cache.url)
    html = ""
    case data["type"]
    when "video", "rich"
      if cache.is_trusted_and_has_html?
        html = data["html"]
      elsif data.has_key?("thumbnail_url")
        html = link_to_oembed_image(cache)
      end
    when "photo"
      if data.has_key?("url")
        html = link_to_oembed_image(cache, "")
      end
    else
      html = link_to(title, cache.url, target: "_blank")
    end

    html.gsub("http://", "https://").html_safe
  end

  def link_to_oembed_image(cache, prefix = "thumbnail_")
    link_to(oembed_image_tag(cache, prefix), cache.url, target: "_blank")
  end

  def oembed_image_tag(cache, prefix)
    image_tag(cache.data[prefix + "url"], cache.options_hash(prefix))
  end
end
