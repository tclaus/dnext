module Querying
  def public_posts(_user)
    Post.all_public_no_nsfw
        .aspect_visibility_ids
  end

  # @param [TrueClass] with_order
  def posts_from(person, with_order=true)
    base_query = Post.from_person_visible_by_user(self, person)
    return base_query.order("posts.created_at desc") if with_order

    base_query
  end
end
