class Post < ApplicationRecord
  belongs_to :person

  scope :all_public, -> {where(public: true)}

end
