# frozen_string_literal: true

class Workers::ReceivePublicJob < Workers::ReceiveBaseJob
  def perform(data, legacy: false)
    filter_errors_for_retry do
      DiasporaFederation::Federation::Receiver.receive_public(data)
    end
  end
end
