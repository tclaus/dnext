# frozen_string_literal: true

class TagFollowing < ApplicationRecord
  belongs_to :user
  belongs_to :tag

  validates_uniqueness_of :tag_id, scope: :user_id

  def self.user_is_following?(user, tag_name)
    tag_name.nil? ? false : joins(:tag).where(tags: {name: tag_name.downcase}).where(user_id: user.id).exists?
  end
end
