# frozen_string_literal: true

class User
  alias share_with_original share_with

  def share_with(*args)
    disable_send_workers
    inlined_jobs do
      share_with_original(*args)
    end
  end

  def add_contact_to_aspect(contact, aspect)
    return if AspectMembership.exists?(contact_id: contact.id, aspect_id: aspect.id)

    contact.aspect_memberships.create!(aspect: aspect)
  end

  def post(class_name, opts={})
    disable_send_workers

    inlined_jobs do
      aspects = aspects_from_ids(opts[:to])

      p = build_post(class_name, opts)
      p.aspects = aspects

      if class_name == :photo
        p.width = 42 unless opts.has_key? :width
        p.height = 42 unless opts.has_key? :height
      end

      if p.save!
        self.aspects.reload

        dispatch_opts = {
          url: Rails.application.routes.url_helpers.post_url(p, host: AppConfig.pod_uri.to_s),
          to:  opts[:to]
        }
        dispatch_post(p, dispatch_opts)
      end
      unless opts[:created_at]
        p.created_at = Time.now - 1
        p.save
      end
      p
    end
  end

  def build_comment(options={})
    Comment::Generator.new(self, options.delete(:post), options.delete(:text)).build(options)
  end

  def disable_send_workers
    RSpec.current_example&.example_group_instance&.instance_eval do
      allow(SendPrivateJob).to receive(:perform_later)
      allow(SendPublicJob).to receive(:perform_later)
    end
  end
end
