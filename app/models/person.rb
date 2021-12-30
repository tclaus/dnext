class Person < ApplicationRecord
  has_many :posts, foreign_key: :author_id, dependent: :destroy
  has_many :photos, foreign_key: :author_id, dependent: :destroy

  belongs_to :owner, class_name: "User", optional: true
  belongs_to :pod

  has_one :profile, dependent: :destroy
  delegate :last_name, :full_name, :image_url, :tag_string, :bio, :location,
           :gender, :birthday, :formatted_birthday, :tags, :searchable,
           :public_details?, to: :profile

  validates :diaspora_handle, :uniqueness => true

  scope :remote, -> { where('people.owner_id IS NULL') }
  scope :local, -> { where('people.owner_id IS NOT NULL') }

  def avatar_small
    profile.image_url(size: :thumb_small)
  end
end
