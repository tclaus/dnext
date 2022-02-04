class Report < ApplicationRecord
  validates :user_id, presence: true
  validates :item_id, presence: true
  validates :item_type, presence: true, inclusion: {
    in: %w[Post Comment], message: "Type should match `Post` or `Comment`!"
  }
  validates :text, presence: true

  validate :entry_does_not_exist, on: :create
  validate :post_or_comment_does_exist, on: :create

  belongs_to :user
  belongs_to :post, optional: true
  belongs_to :comment, optional: true
  belongs_to :reportable, polymorphic: true
  delegate :author, to: :reportable

  STATUS_DELETED = "deleted"
  STATUS_NO_ACTION = "no action"

  after_commit :send_report_notification, on: :create

  scope :join_originator, -> {
    joins("LEFT JOIN people ON originator_diaspora_handle = people.diaspora_handle ")
      .select("reports.*, people.guid as originator_guid")
  }

  def reported_author
    item&.author
  end

  def entry_does_not_exist
    if Report.where(item_id: item_id, item_type: item_type).exists?(user_id: user_id)
      errors[:base] << "You cannot report the same post twice."
    end
  end

  def post_or_comment_does_exist
    if Post.find_by_id(item_id).nil? && Comment.find_by_id(item_id).nil?
      errors[:base] << "Post or comment was already deleted or doesn't exists."
    end
  end

  def destroy_reported_item
    case item
    when Post
      if item.author.local?
        item.author.owner.retract(item)
      else
        item.destroy
      end
    when Comment
      if item.author.local?
        item.author.owner.retract(item)
      elsif item.parent.author.local?
        item.parent.author.owner.retract(item)
      else
        item.destroy
      end
    else
      errors[:base] << "Unknown target type"
    end
    mark_as_reviewed_and_deleted
  end

  def mark_as_reviewed_and_deleted
    Report.where(item_id: item_id, item_type: item_type)
      .update_all(reviewed: true, action: STATUS_DELETED)
  end

  def mark_as_reviewed
    Report.where(item_id: item_id, item_type: item_type)
      .update_all(reviewed: true, action: STATUS_NO_ACTION)
  end

  # rubocop:enable Rails/SkipsModelValidations

  def action_deleted?
    action&.downcase == STATUS_DELETED.downcase
  end

  def action_no_action?
    action&.downcase == STATUS_NO_ACTION.downcase
  end

  def send_report_notification
    # Workers::Mail::ReportWorker.perform_async(id) #TODO: Send notification
  end
end
