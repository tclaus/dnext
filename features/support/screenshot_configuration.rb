After do |scenario|
  Capybara.save_path = ENV.fetch("SCREENSHOT_PATH", nil)
  if scenario.failed? && ENV["SCREENSHOT_PATH"]
    Capybara.page.save_screenshot("#{Time.now.utc} #{scenario.name}.png",
                                  full: true)
  end
end
