class Post < ApplicationRecord
  include Diaspora::Commentable

  belongs_to :commentable, class_name: "Comment", touch: true, polymorphic: true, counter_cache: true
  belongs_to :author, class_name: "Person", inverse_of: :posts, optional: true
  belongs_to :o_embed_cache, optional: true
  belongs_to :open_graph_cache, optional: true

  scope :all_public, lambda {
    includes({author: :profile})
    left_outer_joins(author: [:pod])
      .where("(pods.blocked = false or pods.blocked is null)")
      .where(public: true)
  }

  scope :all_local_public, lambda {
    where(" exists (
      select 1 from people where posts.author_id = people.id
      and people.pod_id is null)
      and posts.public = true")
  }

  def post_type
    self.class.name
  end

  def rendered_message
    Diaspora::MessageRenderer.new(text).markdownified
  end
end
