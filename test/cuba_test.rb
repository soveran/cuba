$:.unshift(File.join("..", "lib"))

require "cuba"
require "cuba/test"

form = <<EOS
  <form action="/login" method="post">
    <input name="user">
    <input type="submit" value="Login">
  </form>
EOS

Cuba.define do
  on get do
    on path("login") do
      res.write "Enter your username"
      res.write form
    end

    on default do
      res.redirect "/login"
    end
  end

  on post, path("login") do
    on param("user") do |user|
      res.write "Got #{user}"
    end
  end
end

Cuba.test "Sample Site" do
  story "As a user I want to be able to login" do
    scenario "A user submits good info" do
      visit "/"

      assert_contain "Enter your username"

      fill_in "user", :with => "Michel"
      click_button "Login"

      assert_contain "Got Michel"
    end
  end
end
