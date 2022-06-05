# frozen_string_literal: true

Then(/^take a screenshot$/) do
  take_screenshot
end

def take_screenshot
  Capybara.save_path = ENV.fetch("SCREENSHOT_PATH", "./tmp")
  Capybara.page.save_screenshot("#{Time.now.utc}.png", full: true)
end
