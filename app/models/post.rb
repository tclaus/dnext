class Post < ApplicationRecord
  belongs_to :author, class_name: "Person", inverse_of: :posts, optional: true

  scope :all_public, -> {
    left_outer_joins(author: [:pod])
      .where("(pods.blocked = false or pods.blocked is null)")
      .where(public: true)
  }

  scope :all_local_public, -> {
    where(" exists (
      select 1 from people where posts.author_id = people.id
      and people.pod_id is null)
      and posts.public = true")
  }

end
