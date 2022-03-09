class StatusMessage < Post
  include Reference::Source
  include Reference::Target

  include PeopleHelper

  validates :text, length: {maximum: 65_535, message: proc {|_p, v|
                                                        I18n.t("status_messages.too_long", count: 65_535, current_length: v[:value].length)
                                                      }}
  before_save :update_text_language

  # don't allow creation of empty status messages
  validate :presence_of_content, on: :create

  has_many :photos, dependent: :destroy, foreign_key: :status_message_guid, primary_key: :guid

  has_one :location, dependent: :destroy
  has_one :poll, autosave: true, dependent: :destroy
  has_many :poll_participations, through: :poll

  attr_accessor :oembed_url
  attr_accessor :open_graph_url

  after_commit :queue_gather_oembed_data, on: :create, if: :contains_oembed_url_in_text?
  after_commit :queue_gather_open_graph_data, on: :create, if: :contains_open_graph_url_in_text?

  # scopes
  scope :where_person_is_mentioned, ->(person) {
    owned_or_visible_by_user(person.owner).joins(:mentions).where(mentions: {person_id: person.id})
  }

  def self.model_name
    Post.model_name
  end

  def self.guids_for_author(person)
    Post.connection.select_values(Post.where(author_id: person.id).select("posts.guid").to_sql)
  end

  def self.any_user_tag_stream(user, tag_ids)
    owned_or_visible_by_user(user).any_tag_stream(tag_ids)
  end

  def self.user_query_stream(user, query, page)
    owned_or_visible_by_user(user).query_stream(query, page)
  end

  def self.user_tag_stream(user, tag_ids)
    owned_or_visible_by_user(user).all_tag_stream(tag_ids)
  end

  def self.public_all_tag_stream(tag_ids)
    all_public.select("DISTINCT #{table_name}.*").all_tag_stream(tag_ids)
  end

  def self.public_any_tag_stream(tag_ids)
    all_public.select("DISTINCT #{table_name}.*").any_tag_stream(tag_ids)
  end

  def self.query_stream(query, page)
    response = Post.search query, from: (page - 1) * 10
    where(posts: {id: response.results.map(&:id)})
  end

  def self.any_tag_stream(tag_ids)
    joins(:taggings).where("taggings.tag_id IN (?)", tag_ids)
  end

  def self.all_tag_stream(tag_ids)
    if tag_ids.empty?
      # A empty list means an unknown tag in Taggings list
      tag_ids = [-1]
    end

    joins("INNER JOIN (
      SELECT taggable_id FROM taggings
      WHERE taggings.tag_id IN (#{tag_ids.join(',')}) AND taggings.taggable_type = 'Post'
      GROUP BY taggable_id
      HAVING COUNT(*) >= #{tag_ids.length})
      taggable ON taggable.taggable_id = posts.id")
  end

  def nsfw
    !!(text.try(:match, /#nsfw/i) || super)
  end

  def comment_email_subject
    if message.present?
      message.title
    elsif photos.present?
      I18n.t("posts.show.photos_by", count: photos.size, author: author_name)
    end
  end

  def first_photo_url(*args)
    photos.first.url(*args)
  end

  def text_and_photos_blank?
    text.blank? && photos.blank?
  end

  def queue_gather_oembed_data
    Workers::GatherOEmbedData.perform_async(id, oembed_url)
  end

  def queue_gather_open_graph_data
    Workers::GatherOpenGraphData.perform_async(id, open_graph_url)
  end

  def contains_oembed_url_in_text?
    urls = message.urls
    self.oembed_url = urls.find {|url| !TRUSTED_OEMBED_PROVIDERS.find(url).nil? }
  end

  def contains_open_graph_url_in_text?
    return nil if contains_oembed_url_in_text?

    self.open_graph_url = message.urls[0]
  end

  def post_location
    {
      address: location.try(:address),
      lat:     location.try(:lat),
      lng:     location.try(:lng)
    }
  end

  def receive(recipient_user_ids)
    super(recipient_user_ids)

    photos.each {|photo| photo.receive(recipient_user_ids) }
  end

  # NOTE: the next two methods can be safely removed once changes from #6818 are deployed on every pod
  # see StatusMessageCreationService#dispatch
  # Only includes those people, to whom we're going to send a federation entity
  # (and doesn't define exhaustive list of people who can receive it)
  def people_allowed_to_be_mentioned
    @aspects_ppl ||=
      if public?
        :all
      else
        Contact.joins(:aspect_memberships).where(aspect_memberships: {aspect: aspects}).distinct.pluck(:person_id)
      end
  end

  def filter_mentions
    return if people_allowed_to_be_mentioned == :all

    update(text: Diaspora::Mentionable.filter_people(text, people_allowed_to_be_mentioned))
  end

  private

  def presence_of_content
    errors[:base] << "Cannot create a StatusMessage without content" if text_and_photos_blank?
  end
end
