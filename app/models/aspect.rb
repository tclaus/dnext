# frozen_string_literal: true

class Aspect < ApplicationRecord
  belongs_to :user

  has_many :aspect_memberships, dependent: :destroy
  has_many :contacts, through: :aspect_memberships

  has_many :aspect_visibilities, dependent: :destroy
  has_many :posts, through: :aspect_visibilities, source: :shareable, source_type: "Post"
  has_many :photos, through: :aspect_visibilities, source: :shareable, source_type: "Photo"

  validates :name, presence: true, length: { maximum: 20 }

  validates_uniqueness_of :name, scope: :user_id, case_sensitive: false

  before_validation do
    name.strip!
  end

  before_create do
    self.order_id ||= Aspect.where(user_id: user_id).maximum(:order_id || 0).to_i + 1
  end

  def to_s
    name
  end

  def <<(shareable)
    case shareable
    when Post
      posts << shareable
    when Photo
      photos << shareable
    else
      raise "Unknown shareable type '#{shareable.class.base_class}'"
    end
  end
end
