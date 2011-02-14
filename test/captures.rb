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
    on get, path("home") do |*args|
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
    on get, path("user"), segment do |id|
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
    on get, path("user"), number do |id|
      res.write id
    end
  end
  
  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/user/101",
          "SCRIPT_NAME" => "/" }

  _, _, resp = Cuba.call(env)

  assert_equal ["101"], resp.body
end

test "yields an extension" do
  Cuba.define do
    on get, path("css"), extension("css") do |file|
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
    on get, path("signup"), param("email") do |email|
      res.write email
    end
  end
  
  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/signup",
          "SCRIPT_NAME" => "/", "rack.input" => StringIO.new,
          "QUERY_STRING" => "email=john@doe.com" }

  _, _, resp = Cuba.call(env)

  assert_equal ["john@doe.com"], resp.body
end
