# frozen_string_literal: true

class Like < ApplicationRecord
  include Diaspora::Federated::Base
  include Diaspora::Fields::Guid
  include Diaspora::Fields::Author
  include Diaspora::Fields::Target
  include Diaspora::Relayable

  has_one :signature, class_name: "LikeSignature", dependent: :delete

  alias_attribute :parent, :target

  after_commit on: :create do
    parent.update_likes_counter
  end

  class Generator < Diaspora::Federated::Generator
    def self.federated_class
      Like
    end

    def relayable_options
      {target: @target, positive: true}
    end
  end

  after_commit on: :create do
    parent.update_likes_counter
  end

  after_destroy do
    parent.update_likes_counter
    participation = author.participations.find_by(target_id: target.id)
    participation.unparticipate! if participation.present?
  end
end
