# frozen_string_literal: true

module Diaspora
  module Federated
    class Retraction
      include Diaspora::Federated::Base
      include Diaspora::Logging

      attr_reader :subscribers, :data

      def initialize(data, subscribers, target=nil)
        @data = data
        @subscribers = subscribers
        @target = target
      end

      def self.entity_class
        DiasporaFederation::Entities::Retraction
      end

      def self.retraction_data_for(target)
        DiasporaFederation::Entities::Retraction.new(
          target_guid: target.guid,
          target:      Diaspora::Federation::Entities.related_entity(target),
          target_type: Diaspora::Federation::Mappings.entity_name_for(target),
          author:      target.diaspora_handle
        ).to_h
      end

      def self.for(target)
        federation_retraction_data = retraction_data_for(target)
        new(federation_retraction_data, target.subscribers.select(&:remote?), target)
      end

      def defer_dispatch(user, include_target_author=true)
        subscribers = dispatch_subscribers(include_target_author)
        DeferredRetractionJob.perform_later(user.id,
                                            self.class.to_s,
                                            data,
                                            subscribers.map(&:id),
                                            service_opts(user))
      end

      def perform
        logger.debug "Performing retraction for #{target.class.base_class}:#{target.guid}"
        target.destroy!
        logger.info "event=retraction status=complete target=#{data[:target_type]}:#{data[:target_guid]}"
      end

      def public?
        data[:target][:public]
      end

      private

      attr_reader :target

      def dispatch_subscribers(include_target_author)
        if target.is_a?(Diaspora::Relayable) && include_target_author && target.author.remote?
          subscribers << target.author
        end
        subscribers
      end

      def service_opts(user)
        return {} unless target.is_a?(StatusMessage)

        user.services.each_with_object(service_types: []) do |service, opts|
          service_opts = service.post_opts(target)
          if service_opts
            opts.merge!(service_opts)
            opts[:service_types] << service.class.to_s
          end
        end
      end
    end
  end
end
