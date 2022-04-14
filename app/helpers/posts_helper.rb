module PostsHelper
  def post_page_title(post, opts={})
    if post.is_a?(Photo)
      I18n.t "posts.show.photos_by", count: 1, author: post.status_message_author_name
    elsif post.is_a?(Reshare)
      I18n.t "posts.show.reshare_by", author: post.author_name
    elsif post.message.present?
      post.message.title opts
    elsif post.respond_to?(:photos) && post.photos.present?
      I18n.t "posts.show.photos_by", count: post.photos.size, author: post.author_name
    end
  end
end
