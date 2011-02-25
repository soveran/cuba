require File.expand_path("helper", File.dirname(__FILE__))
require "stringio"

test "doesn't yield HOST" do
  Cuba.define do
    on host("example.com") do |*args|
      res.write args.size
    end
  end

  env = { "HTTP_HOST" => "example.com" }

  _, _, resp = Cuba.call(env)

  assert_equal ["0"], resp.body
end

test "doesn't yield the verb" do
  Cuba.define do
    on get do |*args|
      res.write args.size
    end
  end

  env = { "REQUEST_METHOD" => "GET" }

  _, _, resp = Cuba.call(env)

  assert_equal ["0"], resp.body
end

test "doesn't yield the path" do
  Cuba.define do
    on get, "home" do |*args|
      res.write args.size
    end
  end

  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/home",
          "SCRIPT_NAME" => "/" }

  _, _, resp = Cuba.call(env)

  assert_equal ["0"], resp.body
end

test "yields the segment" do
  Cuba.define do
    on get, "user", :id do |id|
      res.write id
    end
  end

  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/user/johndoe",
          "SCRIPT_NAME" => "/" }

  _, _, resp = Cuba.call(env)

  assert_equal ["johndoe"], resp.body
end

test "yields a number" do
  Cuba.define do
    on get, "user", :id do |id|
      res.write id
    end
  end

  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/user/101",
          "SCRIPT_NAME" => "/" }

  _, _, resp = Cuba.call(env)

  assert_equal ["101"], resp.body
end

test "yields an extname" do
  Cuba.define do
    on get, "css", extname("css") do |file|
      res.write file
    end
  end

  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/css/app.css",
          "SCRIPT_NAME" => "/" }

  _, _, resp = Cuba.call(env)

  assert_equal ["app"], resp.body
end

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

test "yields a segment per nested block" do
  Cuba.define do
    on :one do |one|
      on :two do |two|
        on :three do |three|
          res.write one
          res.write two
          res.write three
        end
      end
    end
  end

  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/one/two/three",
          "SCRIPT_NAME" => "/" }

  _, _, resp = Cuba.call(env)

  assert_equal ["one", "two", "three"], resp.body
end

test "consumes a slash if needed" do
  Cuba.define do
    on get, "(.+\\.css)" do |file|
      res.write file
    end
  end

  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/foo/bar.css",
          "SCRIPT_NAME" => "/" }

  _, _, resp = Cuba.call(env)

  assert_equal ["foo/bar.css"], resp.body
end