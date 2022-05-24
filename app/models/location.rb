class Location < ApplicationRecord
  # include Diaspora::Federated::Base
  include Diaspora::Federated::Base

  before_validation :split_coords, on: :create
  validates_presence_of :lat, :lng

  attr_accessor :coordinates

  belongs_to :status_message, foreign_key: :status_message

  def split_coords
    self.lat, self.lng = coordinates.split(",") if coordinates.present?
  end
end
