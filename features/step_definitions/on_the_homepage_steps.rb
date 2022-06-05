require "capybara"

Then("I should see a header and a footer section") do
  expect(page).to have_selector("header")
  expect(page).to have_selector("footer")
end
