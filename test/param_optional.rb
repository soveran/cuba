require File.expand_path("helper", File.dirname(__FILE__))
require "stringio"

prepare do
  Cuba.define do
    on get, "signup", param?("email") do |email|

      if email.to_s.empty?
        res.write("no email provided")
      else
        res.write email
      end

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

test "yield an optional param" do
  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/signup",
          "SCRIPT_NAME" => "/", "rack.input" => StringIO.new,
          "QUERY_STRING" => "" }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["no email provided"]
end

test "yield an empty param" do
  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/signup",
          "SCRIPT_NAME" => "/", "rack.input" => StringIO.new,
          "QUERY_STRING" => "email=" }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["no email provided"]
end
