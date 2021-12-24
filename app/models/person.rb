class Person < ApplicationRecord
  has_many :posts, foreign_key: :author_id, dependent: :destroy
  has_many :photos, foreign_key: :author_id, dependent: :destroy
  
  belongs_to :owner, class_name: "User", optional: true
  belongs_to :pod
  has_one :profile, dependent: :destroy

end
