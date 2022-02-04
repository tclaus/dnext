class NotificationActor < ApplicationRecord
  belongs_to :notification
  belongs_to :person
end
