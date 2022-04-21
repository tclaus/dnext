# frozen_string_literal: true

class DeferredDispatchJob < ApplicationJob
  sidekiq_options queue: :high

  def perform(user_id, object_class_name, object_id, opts)
    user = User.find(user_id)
    object = object_class_name.constantize.find(object_id)
    opts = ActiveSupport::HashWithIndifferentAccess.new(opts)

    Diaspora::Federation::Dispatcher.build(user, object, opts).dispatch
  rescue ActiveRecord::RecordNotFound # The target got deleted before the job was run
    # Ignored
  end
end
