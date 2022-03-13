module Querying
  def public_posts(_user)
    Post.all_public_no_nsfw
        .aspect_visibility_ids
  end
end
