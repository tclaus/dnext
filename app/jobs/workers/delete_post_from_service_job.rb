# frozen_string_literal: true

class Workers::DeletePostFromServiceJob < Workers::ApplicationJob
  sidekiq_options queue: :high

  def perform(service_id, opts)
    service = Service.find_by(id: service_id)
    opts = ActiveSupport::HashWithIndifferentAccess.new(opts)
    service.delete_from_service(opts)
  end
end
