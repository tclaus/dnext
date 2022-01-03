class Comment < ApplicationRecord
  include Diaspora::Fields::Author
  include Diaspora::Commentable
  include Diaspora::Taggable

  belongs_to :commentable, class_name: "Comment", touch: true, polymorphic: true, counter_cache: true
  has_one :signature, class_name: "CommentSignature", dependent: :delete
  alias_attribute :post, :commentable
  alias_attribute :parent, :commentable

  delegate :name, to: :author, prefix: true
  delegate :comment_email_subject, to: :parent
  delegate :author_name, to: :parent, prefix: true

  validates :text, presence: true, length: {maximum: 65535}

  acts_as_taggable_on :tags
  extract_tags_from :text
  before_create :build_tags

  before_save do
    text&.strip!
  end

  after_commit on: :create do
    parent.touch(:interacted_at) if parent.respond_to?(:interacted_at)
  end

  def text=(text)
    @text = text.to_s.strip # to_s if for nil, for whatever reason
  end

  def rendered_text
    Diaspora::MessageRenderer.new(text).markdownified
  end
end
