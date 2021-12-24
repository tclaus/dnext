class Comment < ApplicationRecord

  belongs_to :commentable, :touch => true, :polymorphic => true
  alias_attribute :post, :commentable
  alias_attribute :parent, :commentable

  has_one :signature, class_name: "CommentSignature", dependent: :delete

  validates :text, presence: true, length: {maximum: 65535}

  before_save do
    self.text.strip! unless self.text.nil?
  end

  def text= text
    self[:text] = text.to_s.strip #to_s if for nil, for whatever reason
  end

end
