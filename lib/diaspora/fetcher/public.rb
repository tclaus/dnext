# frozen_string_literal: true

#   Copyright (c) 2010-2012, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.
module Diaspora
  module Fetcher
    class Public
      include Diaspora::Logging

      # various states that can be assigned to a person to describe where
      # in the process of fetching their public posts we're currently at
      Status_Initial = 0
      Status_Running = 1
      Status_Fetched = 2
      Status_Processed = 3
      Status_Done = 4
      Status_Failed = 5
      Status_Unfetchable = 6

      def self.queue_for(person)
        return if person.pod&.blocked

        Workers::FetchPublicPostsJob.perform_later(person.diaspora_handle) unless person.fetch_status > Status_Initial
      end

      # perform all actions necessary to fetch the public posts of a person
      # with the given diaspora_id
      def fetch!(diaspora_id)
        @person = Person.by_account_identifier diaspora_id
        return unless qualifies_for_fetching?

        begin
          retrieve_and_process_posts
        rescue StandardError => e
          set_fetch_status Public::Status_Failed
          raise e
        end

        set_fetch_status Public::Status_Done
      end

      private

      # checks, that public posts for the person can be fetched,
      # if it is reasonable to do so, and that they have not been fetched already
      def qualifies_for_fetching?
        raise ActiveRecord::RecordNotFound if @person.blank?
        return false if @person.fetch_status == Public::Status_Unfetchable

        # local users don't need to be fetched
        if @person.local?
          set_fetch_status Public::Status_Unfetchable
          return false
        end

        return false if @person.pod&.blocked

        # this record is already being worked on
        return false if @person.fetch_status > Public::Status_Initial

        # ok, let's go
        @person.remote? &&
          @person.fetch_status == Public::Status_Initial
      end

      # call the methods to fetch and process the public posts for the person
      # does some error logging, in case of an exception
      def retrieve_and_process_posts
        begin
          retrieve_posts
        rescue StandardError => e
          logger.error "unable to retrieve public posts for #{@person.diaspora_handle}"
          raise e
        end

        begin
          process_posts
        rescue StandardError => e
          logger.error "unable to process public posts for #{@person.diaspora_handle}"
          raise e
        end
      end

      # fetch the public posts of the person from their server and save the
      # JSON response to `@data`
      def retrieve_posts
        set_fetch_status Public::Status_Running

        logger.info "fetching public posts for #{@person.diaspora_handle}"

        resp = Faraday.get("#{@person.url}people/#{@person.guid}/stream") do |req|
          req.headers["Accept"] = "application/json"
          req.headers["User-Agent"] = "diaspora-fetcher"
        end

        logger.debug "fetched response: #{resp.body.to_s[0..250]}"

        @data = JSON.parse resp.body
        set_fetch_status Public::Status_Fetched
      end

      # process the public posts that were previously fetched with `retrieve_posts`
      # adds posts, which pass some basic sanity-checking
      # @see validate
      def process_posts
        @data.each do |post|
          next unless validate(post)

          logger.info "saving fetched post (#{post['guid']}) to database"

          logger.debug "post: #{post.to_s[0..250]}"

          status_message = StatusMessage.where(guid: post["guid"]).first
          if status_message.present?
            save_photos(post["guid"], post["photos"])
          else
            DiasporaFederation::Federation::Fetcher.fetch_public(@person.diaspora_handle,
                                                                 post["post_type"],
                                                                 post["guid"])
          end

          status_message = StatusMessage.find_by(guid: post["guid"])
          save_comments(status_message, post["interactions"]["comments"])
        end
        set_fetch_status Public::Status_Processed
      end

      def save_comments(status_message, comments)
        return if comments.empty?
        return if status_message.nil?

        comments.each do |comment|
          next if Comment.exists?(guid: comment["guid"])

          comment_author = Person.find_or_fetch_by_identifier(comment["author"]["diaspora_id"])
          if comment_author.present?
            status_message.comments.create(guid:       comment["guid"],
                                           author:     comment_author,
                                           text:       comment["text"],
                                           created_at: comment["created_at"])
          end
        rescue StandardError => e
          logger.error "Error creating a comment: #{e}"
        end
      end

      def save_photos(status_message_guid, photos)
        return if photos.empty?

        photos.each do |photo|
          sizes = photo["sizes"]
          sizes.each do |photo_size, remote_image_url|
            next unless photo_size.eql?("raw")
            next if photo_exist(remote_image_url)

            new_photo = Photo.new(author: @person, status_message_guid: status_message_guid)
            new_photo.update_remote_path_by_name(remote_image_url)
            new_photo.height = photo["dimensions"]["height"]
            new_photo.width = photo["dimensions"]["width"]
            new_photo.public = true
            new_photo.save
          end
        end
      end

      # set and save the fetch status for the current person
      def set_fetch_status(status)
        return if @person.nil?

        @person.fetch_status = status
        @person.save
      end

      def photo_exist(remote_photo_url)
        name_start = remote_photo_url.rindex "/"
        photo_path = "#{remote_photo_url.slice(0, name_start)}/"
        photo_name = remote_photo_url.slice(name_start + 1, remote_photo_url.length)
        Photo.exists?(remote_photo_path: photo_path, remote_photo_name: photo_name)
      end

      # perform various validations to make sure the post can be saved without
      # troubles
      # @see check_existing
      # @see check_author
      # @see check_public
      # @see check_type
      def validate(post)
        check_author(post) && check_public(post) && check_type(post)
      end

      # checks if the author of the given post is actually from the person
      # we're currently processing
      def check_author(post)
        guid = post["author"]["guid"]
        equal = (guid == @person.guid)

        unless equal
          logger.warn "the author (#{guid}) does not match the person currently being processed (#{@person.guid})"
        end

        equal
      end

      # returns weather the given post is public
      def check_public(post)
        is_public = (post["public"] == true)

        logger.warn "the post (#{post['guid']}) is not public, this is not intended..." unless is_public

        is_public
      end

      # see, if the type of the given post is something we can handle
      def check_type(post)
        type_ok = (post["post_type"] == "StatusMessage")

        unless type_ok
          logger.warn "the post (#{post['guid']}) has a type, which cannot be handled (#{post['post_type']})"
        end

        type_ok
      end
    end
  end
end
