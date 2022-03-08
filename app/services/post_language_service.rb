# frozen_string_literal: true

class PostLanguageService
  # Detect language of a post. Checks for text, text of origin post if reshare and open graph content if
  # no language was found.
  def detect_post_language(post)
    original_post = root_post(post)
    return if original_post.nil?

    return if original_post.text.nil?

    result = nil
    result = language_for_text(original_post.text.to_s) if original_post.text.present?
    result = language_by_heuristic(post) if result.nil?
    return unless result

    post.language_id = result.language.to_s.split("_").first if result.reliable?
  end

  def root_post(post)
    if post.type.eql?("Reshare")
      root_post = Post.find_by(guid: post.root_guid)
      return root_post unless root_post.nil?
    end
    post
  end

  # If a post can not be get a used language directly, it look to the other posts from same user.
  def language_by_heuristic(_post)
    reference = Post.where("author_id = posts.author_id and language_id is not null")
                    .group(:language_id)
                    .order(count_all: :desc)
                    .count
                    .first
    return if reference.nil? || reference.first.nil?

    post_language = PostLanguage.new
    post_language.language = reference.first
    post_language.reliable = true
    post_language
  end

  # @param [String] text to detect language
  def language_for_text(text)
    text_without_url = remove_urls_from_text(text)
    CLD.find_language(text_without_url)
  end

  def remove_urls_from_text(text)
    pattern = %r{((([A-Za-z]{3,9}:(?://)?)(?:[\-;:&=+$,\w]+@)?[A-Za-z0-9.\-]+|(?:www\.|[\-;:&=+$,\w]+@)[A-Za-z0-9.\-]+)((?:/[+~%/.\w\-_]*)?\??(?:[\-+=&;%@.\w_]*)#?(?:[.!/\\\w]*))?)}
    text.gsub(pattern, "").strip
  end

  class PostLanguage
    attr_accessor :language, :reliable

    def reliable?
      reliable
    end
  end
end
