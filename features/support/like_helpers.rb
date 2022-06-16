# frozen_string_literal: true

def like_stream_post(post_text)
  within_post(post_text) do
    action = find(:css, "a.like").text
    find(:css, "a.like").click
    expect(find(:css, "a.like")).not_to have_text(action)
  end
end

def within_post(post_text, &block)
  within find_post_by_text(post_text), &block
end

def find_post_by_text(text)
  expect(page).to have_text(text)
  find(".stream-element", text: text)
end

def like_single_page_post
  within("#actions") do
    find(:css, 'a[title="Like"]').click
  end
end
