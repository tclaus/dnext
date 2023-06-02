# frozen_string_literal: true

module UserServices
  class Connecting
    def initialize(user)
      @user = user
    end

    # This will create a contact on the side of the sharer and the sharee.
    # @param [Person] person The person to start sharing with.
    # @param [Aspect] aspect The aspect to add them to.
    # @return [Contact] The newly made contact for the passed in person.
    def share_with(person, aspect)
      return if user.blocks.exists?(person_id: person.id)

      contact = user.contacts.find_or_initialize_by(person_id: person.id)
      return nil unless contact.valid?

      needs_dispatch = !contact.receiving?
      contact.receiving = true
      contact.aspects << aspect
      contact.save

      if needs_dispatch
        Diaspora::Federation::Dispatcher.defer_dispatch(user, contact)
        deliver_profile_update(subscriber_ids: [person.id]) unless person.local?
      end

      Notifications::StartedSharing.where(recipient_id: user.id, target: person.id, unread: true)
                                   .update_all(unread: false)

      contact
    end

    def disconnect(contact)
      if contact.person.local?
        raise "FATAL: user entry is missing from the DB. Aborting" if contact.person.owner.nil?

        contact.person.owner.disconnected_by(contact.user.person)
      else
        Diaspora::Federated::ContactRetraction.for(contact).defer_dispatch(user)
      end

      contact.aspect_memberships.delete_all

      disconnect_contact(contact, direction: :receiving, destroy: !contact.sharing)
    end

    def disconnected_by(person)
      contact_for(person).try {|contact|
        disconnect_contact(contact, direction: :sharing, destroy: !contact.receiving)
      }
    end

    private

    attr_reader :user

    def deliver_profile_update(opts)
      Profile.new(user).deliver_profile_update(opts)
    end

    def disconnect_contact(contact, direction:, destroy:)
      if destroy
        contact.destroy
      else
        contact.update(direction => false)
      end
    end
  end
end
