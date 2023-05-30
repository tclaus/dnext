# frozen_string_literal: true

module Diaspora
  module Fetcher
    class PublicPostsFromPod
      include Diaspora::Logging

      # Public posts are fetched by asking for public posts, but
      # thn receiving every sent authors posts.
      # @param [Pod] pod to fetch public posts
      def self.queue_for(pod)
        return if pod&.blocked
        return if pod&.status != Pod.no_errors

        Workers::FetchPublicPostsJob.perform_later(pod)
      end

      def fetch!(pod)
        @pod = pod
        return unless @pod.software.starts_with?("diaspora")
        return if @pod.blocked
        return if @pod.status != "no_errors"

        retrieve_public_posts
        process_public_posts
      end

      def retrieve_public_posts
        logger.info "fetching public posts for pod #{@pod.host}"
        url = "#{@pod.uri}/public"
        logger.info "Url: #{url}"
        response = Faraday.get(url) do |request|
          request.headers["Accept"] = "application/json"
          request.headers["User-Agent"] = "diaspora-fetcher"
        end

        logger.debug "fetched response from pod: #{response.body.to_s[0..250]}"
        @data = JSON.parse(response.body)
      end

      def process_public_posts
        @data.each do |post_data|
          diaspora_id = post_data["author"]["diaspora_id"]
          person = Person.find_or_fetch_by_identifier(diaspora_id)
          logger.debug "Found post author to fetch #{person}"
          # Start a new job to get authors posts
          Diaspora::Fetcher::Public.queue_for(person) unless person.nil?
        end
      end
    end
  end
end
