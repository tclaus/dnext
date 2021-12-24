class CommentSignature < ApplicationRecord
  self.primary_key = :comment_id
  belongs_to :comment
end
