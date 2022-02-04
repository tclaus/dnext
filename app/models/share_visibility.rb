class ShareVisibility < ApplicationRecord
  belongs_to :user
  belongs_to :shareable, polymorphic: true
  validate :not_public

  scope :for_a_user, ->(user) {
    where(user_id: user.id)
  }

  scope :for_shareable, ->(shareable) {
    where(shareable_id: shareable.id, shareable_type: shareable.class.base_class.to_s)
  }

  # Perform a batch import, given a set of users and a shareable
  # @note performs linear insertions in postgres
  # @param user_ids [Array<Integer>] Recipients
  # @param share [Shareable]
  # @return [void]
  def self.batch_import(user_ids, share)
    return false if share.public?

    user_ids -= ShareVisibility.for_shareable(share).where(user_id: user_ids).pluck(:user_id)
    return false if user_ids.empty?

    create_visibilities(user_ids, share)
  end

  private

  private_class_method def self.create_visibilities(user_ids, share)
    user_ids.each do |user_id|
      ShareVisibility.find_or_create_by(
        user_id: user_id,
        shareable_id: share.id,
        shareable_type: share.class.base_class.to_s
      )
    end
  end

  def not_public
    errors[:base] << "Cannot create visibility for a public object" if shareable.public?
  end
end
