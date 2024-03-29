# frozen_string_literal: true

module Diaspora
  module Federation
    class Dispatcher
      class Public < Dispatcher
        private

        def deliver_to_services
          deliver_to_hub if object.instance_of?(StatusMessage)
          super
        end

        def deliver_to_remote(people)
          targets = target_urls(people)

          return if targets.empty?

          SendPublicJob.perform_later(sender.id, entity.to_s, targets, magic_envelope.to_xml)
        end

        def target_urls(people)
          active, inactive = Pod.where(id: people.map(&:pod_id).uniq).partition(&:active?)
          logger.info "ignoring inactive pods: #{inactive.join(', ')}" if inactive.any?
          active.map {|pod| pod.url_to("/receive/public") }
        end

        def deliver_to_hub
          logger.debug "deliver to pubsubhubbub sender: #{sender.diaspora_handle}"
          Workers::PublishToHub.perform_later(sender.atom_url)
        end
      end
    end
  end
end
