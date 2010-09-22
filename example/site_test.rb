require "cuba/test"
require File.expand_path("site", File.dirname(__FILE__))

scope do
  test "Login" do
    visit "/"

    assert has_content?("Hello World!")

    fill_in "Your username", :with => "Michel"
    click_button "Login"

    assert has_content?("Got Michel")
  end
end
