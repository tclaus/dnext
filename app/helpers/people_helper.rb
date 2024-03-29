# frozen_string_literal: true

module PeopleHelper
  include ERB::Util

  def search_header
    if search_query.blank?
      content_tag(:h2, t("people.index.no_results"))
    else
      content_tag(:h2, id: "search_title") do
        t("people.index.results_for",
          search_term: content_tag(:span, search_query, class: "term")).html_safe + looking_for_tag_link
      end
    end
  end

  def birthday_format(bday)
    if bday.year <= 1004
      I18n.l bday, format: I18n.t("date.formats.birthday")
    else
      I18n.l bday, format: I18n.t("date.formats.birthday_with_year")
    end
  end

  def person_link(person, opts={})
    css_class = person_link_class(person, opts[:class])
    remote_or_hovercard_link = Rails.application.routes.url_helpers.person_path(person).html_safe
    "<a data-hovercard='#{remote_or_hovercard_link}' href='#{remote_or_hovercard_link}' class='#{css_class}'>"\
    "#{html_escape_once(opts[:display_name] || person.name)}</a>"\
      .html_safe
  end

  def person_image_tag(person, size=:thumb_small)
    return "" if person.nil? || person.profile.nil?

    tag_class = "avatar img-responsive center-block"
    tag_class += " avatar-small" if size == :thumb_small

    image_tag(person.profile.image_url(size: size), alt: person.name, class: tag_class,
              title: person.name, "data-person_id": person.id)
  end

  def person_image_link(person, opts={})
    return "" if person.nil? || person.profile.nil?

    if opts[:to] == :photos
      link_to person_image_tag(person, opts[:size]), person_photos_path(person)
    else
      css_class = person_link_class(person, opts[:class])
      remote_or_hovercard_link = Rails.application.routes.url_helpers.person_path(person).html_safe
      "<a href='#{remote_or_hovercard_link}' class='#{css_class}' #{('target=' + opts[:target]) if opts[:target]}>
      #{person_image_tag(person, opts[:size])}
      </a>".html_safe
    end
  end

  # Rails.application.routes.url_helpers is needed since this is indirectly called from a model
  def local_or_remote_person_path(person, opts={})
    opts.merge!(protocol: AppConfig.pod_uri.scheme, host: AppConfig.pod_uri.authority)
    absolute = opts.delete(:absolute)

    if person.local?
      username = person.username
      unless username.include?(".")
        opts.merge!(username: username)
        if absolute
          return Rails.application.routes.url_helpers.user_profile_url(opts)
        else
          return Rails.application.routes.url_helpers.user_profile_path(opts)
        end
      end
    end

    if absolute
      Rails.application.routes.url_helpers.person_url(person, opts)
    else
      Rails.application.routes.url_helpers.person_path(person, opts)
    end
  end

  def person_share_message(_current_user, person)
    i18nScope = "people.helper.is_not_sharing"
    icon = "entypo-record"
    if person.is_sharing
      i18nScope = "people.helper.is_sharing"
      icon = "entypo-check"
    end

    title = t(i18nScope, {name: _.escape(person.name)})
    '<span class="sharing_message_container" title="' + title + '" data-placement="bottom">' +
    '  <i id="sharing_message" class="' + icon + '"></i>' +
    "</span>"
  end

  def text_formatter(text)
    Diaspora::MessageRenderer.new(text).markdownified
  end

  private

  def person_link_class(person, css_class)
    return css_class unless defined?(user_signed_in?) && user_signed_in?

    return "#{css_class} self" if current_user.person == person

    css_class
  end
end
