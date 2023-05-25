# frozen_string_literal: true

module Workers
  class DeletePostFromServiceJob < Workers::ApplicationJob
    queue_as :high

    def perform(service_id, opts)
      service = Service.find_by(id: service_id)
      opts = ActiveSupport::HashWithIndifferentAccess.new(opts)
      service.delete_from_service(opts)
    end
  end
end
