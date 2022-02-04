class AccountMigration < ApplicationRecord
  belongs_to :old_person, class_name: "Person"
  belongs_to :new_person, class_name: "Person"

  validates :old_person, uniqueness: true
  validates :new_person, presence: true
end
