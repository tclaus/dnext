# frozen_string_literal: true

#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

module Diaspora
  module Likeable
    def self.included(model)
      model.instance_eval do
        has_many :likes, -> { where(positive: true) }, dependent: :delete_all, as: :target
        has_many :dislikes, -> { where(positive: false) }, class_name: "Like", dependent: :delete_all, as: :target
      end
    end

    # @return [Integer]
    def update_likes_counter
      likeable = self.class.where(id: id)
      if likeable
        likeable.update_all(likes_count: likes.count)
        likeable.first.broadcast_like_updates
      end
    end
  end
end
