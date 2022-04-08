# frozen_string_literal: true

module Stream
  class Tag < Stream::Base
    attr_accessor :tag_names, :people_page, :people_per_page

    def initialize(user, tag_names, opts={})
      self.tag_names = tag_names.downcase.gsub("#", "")
      self.people_page = opts[:page] || 1
      self.people_per_page = 15
      super(user, opts)
    end

    def tags
      @tags ||= ActsAsTaggableOn::Tag.named_any(tag_names.split)
    end

    def display_tag_name
      @display_tag_name ||= tag_names.split.map {|t| "##{t}" }.join(" ")
    end

    def tagged_people
      @tagged_people ||= ::Person.profile_tagged_with(tag_names)
    end

    def tagged_people_count
      @tagged_people_count ||= ::Person.profile_tagged_with(tag_names).count
    end

    def posts
      @posts ||= if user
                   StatusMessage.user_tag_stream(user, tags.pluck(:id))
                 else
                   StatusMessage.public_all_tag_stream(tags.pluck(:id))
                 end
    end

    def stream_posts
      return [] unless tags

      super
    end
  end
end
