# frozen_string_literal: true

class OpenGraphCache < ApplicationRecord
  validates :title, presence: true
  validates :ob_type, presence: true
  validates :image, presence: true
  validates :url, presence: true

  has_many :posts, dependent: :nullify

  def image
    if AppConfig.privacy.camo.proxy_opengraph_thumbnails?
      Diaspora::Camo.image_url(self[:image])
    else
      self[:image]
    end
  end

  def self.find_or_create_by(opts)
    cache = OpenGraphCache.find_or_initialize_by(opts)
    cache.fetch_and_save_opengraph_data! unless cache.persisted?
    cache if cache.persisted? # Make this an after create callback and drop this method ?
  end

  def fetch_and_save_opengraph_data!
    uri = URI.parse(url.start_with?("http") ? url : "http://#{url}")
    uri.normalize!
    object = OpenGraphReader.fetch!(uri)
    return unless object

    self.title = object.og.title.truncate(255)
    self.ob_type = object.og.type
    self.image = object.og.image.url
    self.url = object.og.url
    self.description = object.og.description
    self.locale = extract_language_id(object.og.locale)
    detect_language_by_description if locale.nil?
    if object.og.video.try(:secure_url) && secure_video_url?(object.og.video.secure_url)
      self.video_url = object.og.video.secure_url
    end
    save
  rescue OpenGraphReader::NoOpenGraphDataError, OpenGraphReader::InvalidObjectError
    # Ignored
  end

  def secure_video_url?(url)
    SECURE_OPENGRAPH_VIDEO_URLS.any? {|u| u =~ url }
  end

  def detect_language_by_description
    return
    # TODO: Language Service not implemented
    result = language_service.language_for_text(description) if description.present?
    self.locale = result.language.to_s.split("_").first if result.present? && result.reliable?
  end

  def extract_language_id(locale)
    return locale.content.split("_").first unless locale.nil?

    locale
  end

  def language_service
    @language_service ||= LanguageService.new
  end
end
