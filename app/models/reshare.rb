# frozen_string_literal: true

class Reshare < Post
  belongs_to :root, class_name: "Post", foreign_key: :root_guid, primary_key: :guid, optional: true, counter_cache: true
  validate :root_must_be_public
  validates :root, presence: true, on: :create, if: proc {|reshare| reshare.author.local? }
  validates :root_guid, uniqueness: {scope: :author_id}, allow_nil: true
  delegate :author, to: :root, prefix: true

  delegate :o_embed_cache, :open_graph_cache,
           :message, :nsfw,
           to: :absolute_root, allow_nil: true

  before_validation do
    self.public = true
  end

  after_commit on: :create do
    root.update_reshares_counter if root.present?
  end

  after_destroy do
    root.update_reshares_counter if root.present?
  end

  def root_diaspora_id
    root.try(:author).try(:diaspora_handle)
  end

  def mentioned_people
    absolute_root.try(:mentioned_people) || super
  end

  def photos
    absolute_root.try(:photos) || super
  end

  def post_location
    {
      address: absolute_root.try(:location).try(:address),
      lat:     absolute_root.try(:location).try(:lat),
      lng:     absolute_root.try(:location).try(:lng)
    }
  end

  def poll
    absolute_root.try(:poll) || super
  end

  def comment_email_subject
    I18n.t("reshares.comment_email_subject", resharer: author.name, author: root.author_name)
  end

  def absolute_root
    @absolute_root ||= self
    @absolute_root = @absolute_root.root while @absolute_root.is_a? Reshare
    @absolute_root
  end

  def receive(recipient_user_ids)
    super(recipient_user_ids)

    root.author.owner.participate!(self) if root.author.local?
  end

  def subscribers
    super.tap {|people| root.try {|root| people << root.author } }
  end

  private

  def root_must_be_public
    return unless root && !root.public

    errors.add(:base, "Only posts which are public may be reshared.")
    false
  end
end
