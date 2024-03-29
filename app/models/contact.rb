# frozen_string_literal: true

class Contact < ApplicationRecord
  include Diaspora::Federated::Base

  belongs_to :user
  belongs_to :person

  validates :person_id, uniqueness: {scope: :user_id}

  delegate :name, :diaspora_handle, :guid, :first_name,
           to: :person, prefix: true

  has_many :aspect_memberships, dependent: :destroy
  has_many :aspects, through: :aspect_memberships

  validate :not_contact_for_self,
           :not_blocked_user,
           :not_contact_with_closed_account

  before_destroy :destroy_notifications

  scope :all_contacts_of_person, ->(person) { where(person_id: person.id) }

  # contact.sharing is true when contact.person is sharing with contact.user
  scope :sharing, -> { where(sharing: true) }

  # contact.receiving is true when contact.user is sharing with contact.person
  scope :receiving, -> { where(receiving: true) }

  scope :mutual, -> { sharing.receiving }

  scope :for_a_stream, -> { includes(:aspects, person: :profile).order("profiles.last_name ASC") }

  scope :only_sharing, -> { sharing.where(receiving: false) }

  def destroy_notifications
    Notification.where(
      target_type:  "Person",
      target_id:    person_id,
      recipient_id: user_id,
      type:         "Notifications::StartedSharing"
    ).destroy_all
  end

  def mutual?
    sharing && receiving
  end

  def in_aspect?(aspect)
    if aspect_memberships.loaded?
      aspect_memberships.detect {|am| am.aspect_id == aspect.id }
    elsif aspects.loaded?
      aspects.detect {|a| a.id == aspect.id }
    else
      AspectMembership.exists?(contact_id: id, aspect_id: aspect.id)
    end
  end

  # Follows back if user setting is set so
  def receive(_recipient_user_ids)
    user.share_with(person, user.auto_follow_back_aspect) if user.auto_follow_back && !receiving
  end

  # object for local recipients
  def object_to_receive
    Contact.create_or_update_sharing_contact(person.owner, user.person)
  end

  # @return [Array<Person>] The recipient of the contact
  def subscribers
    [person]
  end

  # creates or updates a contact with active sharing flag. Returns nil if already sharing.
  def self.create_or_update_sharing_contact(recipient, sender)
    contact = recipient.contacts.find_or_initialize_by(person_id: sender.id)

    return if contact.sharing

    contact.update(sharing: true)
    contact
  end

  private

  def not_contact_with_closed_account
    errors.add(:base, "Cannot be in contact with a closed account") if person_id && person.closed_account?
  end

  def not_contact_for_self
    errors.add(:base, "Cannot create self-contact") if person_id && person.owner == user
  end

  def not_blocked_user
    if receiving && user && user.blocks.where(person_id: person_id).exists?
      errors.add(:base, "Cannot connect to an ignored user")
    end
  end
end
