class User < ApplicationRecord
  has_one :person, inverse_of: :owner, foreign_key: :owner_id
  
end
