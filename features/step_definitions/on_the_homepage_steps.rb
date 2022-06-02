require "capybara"

Given("I am on the homepage") do
  visit root_path
end

Then("I should see a header and a footer section") do
  expect(page).to have_selector("header")
  expect(page).to have_selector("footer")
end
