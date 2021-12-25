class LikeSignature < ApplicationRecord
  self.primary_key = :like_id
  belongs_to :like
end
