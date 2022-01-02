# frozen_string_literal: true

class OEmbedCache < ApplicationRecord
  serialize :data
  validates :data, presence: true

  has_many :posts

  def self.find_or_create_by(opts)
    cache = OEmbedCache.find_or_initialize_by(opts)
    return cache if cache.persisted?
    cache.fetch_and_save_oembed_data! # make after create callback and drop this method ?
    cache
  end

  def fetch_and_save_oembed_data!
    response = OEmbed::Providers.get(url, {maxwidth: 560, maxheight: 560, frame: 1, iframe: 1})
  rescue => e
    # noop
  else
    self.data = response.fields
    data["trusted_endpoint_url"] = response.provider.endpoint
    save
  end

  def is_trusted_and_has_html?
    from_trusted? and data.has_key?("html")
  end

  def from_trusted?
    SECURE_ENDPOINTS.include?(data["trusted_endpoint_url"])
  end

  def options_hash(prefix = "thumbnail_")
    return nil unless data.has_key?(prefix + "url")
    {
      height: data.fetch(prefix + "height", ""),
      width: data.fetch(prefix + "width", ""),
      alt: data.fetch("title", "")
    }
  end
end
