class Photo < ApplicationRecord
  belongs_to :status_message, foreign_key: :status_message_guid, primary_key: :guid, optional: true
  belongs_to :person, foreign_key: :author_id
  validates_associated :status_message
  delegate :author_name, to: :status_message, prefix: true
end
