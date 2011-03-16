require File.expand_path("helper", File.dirname(__FILE__))
require "stringio"

test "yields a param" do
  Cuba.define do
    on get, "signup", param("email") do |email|
      res.write email
    end
  end

  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/signup",
          "SCRIPT_NAME" => "/", "rack.input" => StringIO.new,
          "QUERY_STRING" => "email=john@doe.com" }

  _, _, resp = Cuba.call(env)

  assert_equal ["john@doe.com"], resp.body
end

test "doesn't yield a blank param" do
  Cuba.define do
    on get, "signup", param("email") do |email|
      res.write email
    end

    on default do
      res.write "No email"
    end
  end

  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/signup",
          "SCRIPT_NAME" => "/", "rack.input" => StringIO.new,
          "QUERY_STRING" => "" }

  _, _, resp = Cuba.call(env)

  assert_equal ["No email"], resp.body
end
