class User < ApplicationRecord
  has_one :person, inverse_of: :owner, foreign_key: :owner_id

  has_many :tag_followings
  has_many :followed_tags, -> { order("tags.name") }, through: :tag_followings, source: ActsAsTaggableOn::Tag
end
