class Like < ApplicationRecord
  belongs_to :person, foreign_key: :author_id, counter_cache: true
end
