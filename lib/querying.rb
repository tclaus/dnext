# frozen_string_literal: true

module Querying
  # @param [TrueClass] with_order
  def posts_from(person, with_order: true)
    base_query = Post.from_person_visible_by_user(self, person)
    return base_query.order("posts.created_at desc") if with_order

    base_query
  end

  def photos_from(person, opts={})
    opts = prep_opts(Photo, opts)
    Photo.from_person_visible_by_user(self, person)
         .limit(opts[:limit])
  end

  def contact_for(person)
    return nil unless person

    contact_for_person_id(person.id)
  end

  def contact_for_person_id(person_id)
    Contact.includes(person: :profile)
           .find_by(user_id: id, person_id: person_id)
  end

  protected

  # @return [Hash]
  def prep_opts(klass, opts)
    defaults = {
      order:  "created_at DESC",
      limit:  15,
      hidden: false
    }
    defaults[:type] = Stream::Base::TYPES_OF_POST_IN_STREAM if klass == Post
    opts = defaults.merge(opts)
    opts.delete(:limit) if opts[:limit] == :all

    opts[:order_field] = opts[:order].split.first.to_sym
    opts[:order_with_table] = "#{klass.table_name}.#{opts[:order]}"

    opts[:max_time] = Time.zone.at(opts[:max_time]) if opts[:max_time].is_a?(Integer)
    opts[:max_time] ||= Time.zone.now + 1
    opts
  end
end
