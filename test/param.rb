require File.expand_path("helper", File.dirname(__FILE__))
require "stringio"

prepare do
  Cuba.define do
    on get, "signup", param("email") do |email|
      res.write email
    end

    on default do
      res.write "No email"
    end
  end
end

test "yields a param" do
  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/signup",
          "SCRIPT_NAME" => "/", "rack.input" => StringIO.new,
          "QUERY_STRING" => "email=john@doe.com" }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["john@doe.com"]
end

test "doesn't yield a missing param" do
  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/signup",
          "SCRIPT_NAME" => "/", "rack.input" => StringIO.new,
          "QUERY_STRING" => "" }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["No email"]
end

test "doesn't yield an empty param" do
  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/signup",
          "SCRIPT_NAME" => "/", "rack.input" => StringIO.new,
          "QUERY_STRING" => "email=" }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["No email"]
end
