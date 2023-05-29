# frozen_string_literal: true

RSpec.describe ApplicationHelper do
  it "Generate peoples links for hovercards" do
    link = link_to_person(guid: "123", css_class: "a_class") do
      "link"
    end
    assert_dom_equal %(<a data-controller="hovercard" data-hovercard-url-value="/people/123/hovercard" data-action="mouseenter-&gt;hovercard#show mouseleave-&gt;hovercard#hide" class="a_class" href="/people/123">link</a>),
                     link
  end
end
