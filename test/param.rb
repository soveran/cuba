require File.expand_path("helper", File.dirname(__FILE__))
require "stringio"

prepare do
  Cuba.define do
    on get, "signup", param("email") do |email|
      res.write email
    end
    
    on get, "search", param("email", false) do |email|
      if email == nil
        res.write "No email is specified"
      else
        res.write email
      end
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

test "doesn't yield a missing param when param is required" do
  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/signup",
          "SCRIPT_NAME" => "/", "rack.input" => StringIO.new,
          "QUERY_STRING" => "" }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["No email"]
end

test "yields a param when param is optional and provided" do
  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/search",
          "SCRIPT_NAME" => "/", "rack.input" => StringIO.new,
          "QUERY_STRING" => "email=john@doe.com" }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["john@doe.com"]
end

test "yields a message when param is optional and not provided" do
  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/search",
          "SCRIPT_NAME" => "/", "rack.input" => StringIO.new,
          "QUERY_STRING" => "" }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["No email is specified"]
end



test "doesn't yield an empty param" do
  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/signup",
          "SCRIPT_NAME" => "/", "rack.input" => StringIO.new,
          "QUERY_STRING" => "email=" }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["No email"]
end
