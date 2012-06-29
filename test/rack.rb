require File.expand_path("helper", File.dirname(__FILE__))
require "cuba/test"

scope do
  test do
    Cuba.define do
      on root do
        res.write "home"
      end

      on "about" do
        res.write "about"
      end
    end

    get "/"
    assert_equal "home", last_response.body

    get "/about"
    assert_equal "about", last_response.body
  end
end
