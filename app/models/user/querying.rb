# frozen_string_literal: true

module User::Querying
  def find_visible_shareable_by_id(klass, id, opts={})
    key = (opts.delete(:key) || :id)
    find_visible_shareable_by_id = EvilQuery::VisibleShareableById.new(self, klass, key, id, opts)
    find_visible_shareable_by_id.post!
  end

  def visible_shareables(klass, opts={})
    opts = prep_opts(klass, opts)
    shareable_ids = visible_shareable_ids(klass, opts)
    klass.where(id: shareable_ids).select("DISTINCT #{klass.table_name}.*")
         .limit(opts[:limit]).order(opts[:order_with_table])
  end

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

  def block_for(person)
    return nil unless person
    blocks.find_by(person_id: person.id)
  end

  def aspects_with_shareable(base_class_name_or_class, shareable_id)
    base_class_name = base_class_name_or_class
    base_class_name = base_class_name_or_class.base_class.to_s if base_class_name_or_class.is_a?(Class)
    self.aspects.joins(:aspect_visibilities).where(:aspect_visibilities => {:shareable_id => shareable_id, :shareable_type => base_class_name})
  end

  def contact_for_person_id(person_id)
    Contact.includes(person: :profile)
           .find_by(user_id: id, person_id: person_id)
  end


  # @param [Person] person
  # @return [Boolean] whether person is a contact of this user
  def has_contact_for?(person)
    Contact.exists?(:user_id => self.id, :person_id => person.id)
  end

  def people_in_aspects(requested_aspects, opts={})
    allowed_aspects = self.aspects & requested_aspects
    aspect_ids = allowed_aspects.map(&:id)

    people = Person.in_aspects(aspect_ids)

    if opts[:type] == 'remote'
      people = people.where(:owner_id => nil)
    elsif opts[:type] == 'local'
      people = people.where('people.owner_id IS NOT NULL')
    end
    people
  end

  def aspects_with_person(person)
    contact_for(person).aspects
  end

  def posts_from(person, with_order=true)
    base_query = Post.from_person_visible_by_user(self, person)
    return base_query.order("posts.created_at desc") if with_order

    base_query
  end

  def photos_from(person, opts={})
    opts = prep_opts(Photo, opts)
    Photo.from_person_visible_by_user(self, person)
         .by_max_time(opts[:max_time])
         .limit(opts[:limit])
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
