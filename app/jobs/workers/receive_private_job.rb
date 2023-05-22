# frozen_string_literal: true

class Workers::ReceivePrivateJob < Workers::ReceiveBaseJob
  def perform(user_id, data, _legacy)
    filter_errors_for_retry do
      user_private_key = User.where(id: user_id).pluck(:serialized_private_key).first
      rsa_key = OpenSSL::PKey::RSA.new(user_private_key)
      DiasporaFederation::Federation::Receiver.receive_private(data, rsa_key, user_id)
    end
  end
end
