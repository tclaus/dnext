class Profile < ApplicationRecord
  belongs_to :person

  def image_url(size: :thumb_large, fallback_to_default: true)
    result = if size == :thumb_medium && self[:image_url_medium]
      self[:image_url_medium]
    elsif size == :thumb_small && self[:image_url_small]
      self[:image_url_small]
    else
      self[:image_url]
    end
    result || ActionController::Base.helpers.image_path("users/default.png")
  end

  def image_url=(url)
    super(build_image_url(url))
  end

  def image_url_small=(url)
    super(build_image_url(url))
  end

  def image_url_medium=(url)
    super(build_image_url(url))
  end
end
