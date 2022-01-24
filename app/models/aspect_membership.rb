# frozen_string_literal: true

class AspectMembership < ApplicationRecord
  belongs_to :aspect
  belongs_to :contact
  has_one :user, through: :contact
  has_one :person, through: :contact

  before_destroy do
    user&.disconnect(contact) if contact&.aspects&.size == 1
    true
  end

  def as_json(opts = {})
    {
      id: id,
      person_id: person.id,
      contact_id: contact.id,
      aspect_id: aspect_id,
      aspect_ids: contact.aspects.map { |a| a.id }
    }
  end
end
