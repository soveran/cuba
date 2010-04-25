require "cuba/test"
require "site"

Cuba.test "My Site" do
  story "As a user I want to be able to login" do
    scenario "A user submits good info" do
      visit "/"

      assert_contain "Hello World!"

      fill_in "user", :with => "Michel"
      click_button "Login"

      assert_contain "Got Michel"
    end
  end
end
