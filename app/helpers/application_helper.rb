module ApplicationHelper

  # Changes Ruby Class names to CSS class names. Example: StatusMessage => status_message
  # @param [String] name
  # @return [String]
  def classify(name)
    name.underscore.dasherize
  end

  # For the post range this function returns a icon for global, limited or personal visible posts
  # @return span tag with icon for posts range
  def range_tag(post, *args)

    if post.public?
      content = '<i class="bi bi-globe" role="img" arial-label="global visibility"></i>'
    else
      content = '<i class="bi bi-people-fill"></i>'
    end

    content_tag("span", content.html_safe, args)
  end
end
