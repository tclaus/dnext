# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

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
      visibility = t("post.visibility.global")
      content = "<i class=\"bi bi-globe\" role=\"img\" aria-label=\"#{visibility}\" title=\"#{visibility}\"></i>"
    else
      visibility = t("post.visibility.limited")
      content = "<i class=\"bi bi-people-fill\" role=\"img\" aria-label=\"#{visibility}\" title=\"#{visibility}\"></i>"
    end

    content_tag("span", content.html_safe, args)
  end

  # Returns a tag formatted as a link
  def tag_as_link(tag_name)
    link_to("##{tag_name}", "/tags/#{tag_name}", class: "tag")
  end

  def pod_name
    AppConfig.settings.pod_name
  end

  def pod_version
    AppConfig.version.number
  end

  def source_url
    AppConfig.settings.source_url.presence || "#{root_path.chomp('/')}/source.tar.gz"
  end

  def flash_messages
    flash.map do |name, msg|
      klass = flash_class name
      content_tag(:div, msg, class: "flash-body expose") do
        content_tag(:div, msg, class: "flash-message message alert alert-#{klass}", role: "alert")
      end
    end.join(" ").html_safe
  end

  def qrcode_uri
    label = current_user.username
    current_user.otp_provisioning_uri(label, issuer: AppConfig.environment.url)
  end
end
