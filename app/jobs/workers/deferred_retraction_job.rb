# frozen_string_literal: true

module Workers
  class DeferredRetractionJob < Workers::ApplicationJob
    queue_as :high

    def perform(user_id, retraction_class, retraction_data, recipient_ids, opts)
      user = User.find(user_id)
      subscribers = Person.where(id: recipient_ids)
      object = retraction_class.constantize.new(retraction_data.deep_symbolize_keys, subscribers)
      opts = ActiveSupport::HashWithIndifferentAccess.new(opts)

      Diaspora::Federation::Dispatcher.build(user, object, opts).dispatch
    end
  end
end
