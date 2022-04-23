# frozen_string_literal: true

#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class Post < ApplicationRecord
  self.include_root_in_json = false

  include ApplicationHelper
  include Diaspora::Commentable
  include Diaspora::Federated::Base
  include Diaspora::Federated::Fetchable
  include Diaspora::Likeable
  include Diaspora::MentionsContainer
  include Diaspora::Shareable
  include Diaspora::Taggable

  acts_as_taggable_on :tags
  extract_tags_from :text

  attr_accessor :user_like

  has_many :participations, dependent: :delete_all, as: :target, inverse_of: :target
  has_many :participants, through: :participations, source: :author
  has_many :reports, as: :item

  has_many :reshares, class_name: "Reshare", foreign_key: :root_guid, primary_key: :guid
  has_many :resharers, class_name: "Person", through: :reshares, source: :author
  belongs_to :author, class_name: "Person", inverse_of: :posts, optional: true

  belongs_to :o_embed_cache, optional: true
  belongs_to :open_graph_cache, optional: true

  validates :id, uniqueness: true

  after_create do
    touch(:interacted_at)
  end

  before_destroy do
    reshares.update_all(root_guid: nil)
  end

  after_update_commit -> {
    broadcast_like_updates
  }

  def broadcast_like_updates
    broadcast_update_to(:posts, partial: "streams/interactions/own_interactions",
                                locals:  {post: self},
                                target:  "post_own_like_#{id}")

    broadcast_update_to(:posts, partial: "streams/interactions/other_interactions",
                                locals:  {post: self},
                                target:  "post_like_#{id}")
  end

  # scopes
  scope :includes_for_a_stream, lambda {
    includes(:o_embed_cache,
             :open_graph_cache,
             {author: :profile},
             mentions: {person: :profile}) # NOTE: should include root and photos, but i think those are both on status_message
  }

  # all Posts from not blocked pods
  scope :all_not_blocked_pod, -> {
    left_outer_joins(author: [:pod])
      .where("(pods.blocked = false or pods.blocked is null)")
  }

  # Public Posts from not blocked pods
  scope :all_public, lambda {
    includes({author: :profile})
      .where(public: true)
      .left_outer_joins(author: [:pod])
      .where("(pods.blocked = false or pods.blocked is null)")
  }

  # Public posts from local Pod
  scope :all_local_public, lambda {
    where(public: true)
      .where(" exists (
      select 1 from people where posts.author_id = people.id
      and people.pod_id is null)
      and posts.public = true")
  }

  # Public posts without any nsfw tagged content
  scope :all_public_no_nsfw, -> {
    all_public
      .where("posts.id NOT IN
      (SELECT taggings.taggable_id FROM taggings
          INNER JOIN tags ON taggings.tag_id = tags.id AND taggings.taggable_type = 'Post' AND (tags.name = 'nsfw' )
      )")
  }

  # TODO: dont show people from blocked posts
  scope :commented_by, lambda {|person|
    select("DISTINCT posts.*")
      .joins(:comments)
      .where(comments: {author_id: person.id})
  }

  # TODO: dont show likes from people from blocked posts or are blocked
  scope :liked_by, lambda {|person|
    joins(:likes).where(likes: {author_id: person.id})
  }

  scope :subscribed_by, lambda {|user|
    joins(:participations).where(participations: {author_id: user.person_id})
  }

  scope :reshares, -> { where(type: "Reshare") }

  scope :reshared_by, lambda {|person|
    # we join on the same table, Rails renames "posts" to "reshares_posts" for the right table
    joins(:reshares).where(reshares_posts: {author_id: person.id})
  }

  def post_type
    self.class.name
  end

  def root; end

  def photos = []

  # prevents error when trying to access @post.address in a post different than Reshare and StatusMessage types;
  # check PostPresenter
  def address; end

  def poll; end

  # @return An ActiveRecord::Relation of posts
  def self.excluding_hidden_content(relation, user)
    relation = excluding_blocks(relation, user)
    excluding_hidden_shareables(relation, user)
  end

  # exclude blocks from user
  def self.excluding_blocks(relation, user)
    people = user.blocks.map(&:person_id)
    relation = relation.where.not(posts: {author_id: people}) if people.any?
    relation
  end

  def self.excluding_hidden_shareables(relation, user)
    if user.has_hidden_shareables_of_type?
      relation = relation.where.not(posts: {id: user.hidden_shareables[base_class.to_s]})
    end
    relation
  end

  # Adds a relation to filter out blocked user and hidden content
  # @param [ActiveRecord:Relation] relation
  # @param [User] user The current logged in user or nil
  # @param [FalseClass] ignore_blocks True to ignore blocks
  # @return [ActiveRecord:Relation] An ActiveRecord Relation filtered by blocked or invisible content
  def self.for_a_stream(relation, user=nil, ignore_blocks: false)
    relation = relation
               .includes_for_a_stream

    if user.present?
      relation = if ignore_blocks
                   excluding_hidden_shareables(relation, user)
                 else
                   excluding_hidden_content(relation, user)
                 end
    end
    relation
  end

  def reshare_for(user)
    return unless user

    reshares.find_by(author_id: user.person.id)
  end

  def like_for(user)
    return unless user

    likes.find_by(author_id: user.person.id)
  end

  #############

  # @return [Integer]
  def update_reshares_counter
    self.class.where(id: id).update_all(reshares_count: reshares.count)
  end

  def self.diaspora_initialize(params)
    new(params.to_hash.stringify_keys.slice(*column_names, "author"))
  end

  def comment_email_subject
    I18n.t("notifier.a_post_you_shared")
  end

  def nsfw
    author.profile.nsfw?
  end

  def subscribers
    super.tap do |subscribers|
      subscribers.concat(resharers).concat(participants) if public?
    end
  end

  def update_text_language
    language_service.detect_post_language(self) if text_changed?
  end

  def language_service
    @language_service ||= PostLanguageService.new
  end

  def rendered_message
    Diaspora::MessageRenderer.new(text).markdownified
  end
end
