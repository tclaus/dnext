# frozen_string_literal: true

class ReceivePublicJob < ReceiveBaseJob
  def perform(data, legacy: false)
    filter_errors_for_retry do
      DiasporaFederation::Federation::Receiver.receive_public(data)
    end
  end
end
