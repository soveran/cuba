require File.expand_path("helper", File.dirname(__FILE__))

test "doesn't yield HOST" do
  Cuba.define do
    on host("example.com") do |*args|
      res.write args.size
    end
  end

  env = { "HTTP_HOST" => "example.com" }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["0"]
end

test "doesn't yield the verb" do
  Cuba.define do
    on get do |*args|
      res.write args.size
    end
  end

  env = { "REQUEST_METHOD" => "GET" }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["0"]
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

  assert_response resp, ["0"]
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

  assert_response resp, ["johndoe"]
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

  assert_response resp, ["101"]
end

test "yield a file name with a matching extension" do
  Cuba.define do
    on get, "css", extension("css") do |file|
      res.write file
    end
  end

  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/css/app.css",
          "SCRIPT_NAME" => "/" }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["app"]
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

  assert_response resp, ["one", "two", "three"]
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

  assert_response resp, ["foo/bar.css"]
end

test "regex captures in string format" do
  Cuba.define do
    on get, "posts/(\\d+)-(.*)" do |id, slug|
      res.write id
      res.write slug
    end
  end


  env = { "REQUEST_METHOD" => "GET",
          "PATH_INFO" => "/posts/123-postal-service",
          "SCRIPT_NAME" => "/" }

  _, _, resp = Cuba.call(env)


  assert_response resp, ["123", "postal-service"]
end

test "regex captures in regex format" do
  Cuba.define do
    on get, %r{posts/(\d+)-(.*)} do |id, slug|
      res.write id
      res.write slug
    end
  end

  env = { "REQUEST_METHOD" => "GET",
          "PATH_INFO" => "/posts/123-postal-service",
          "SCRIPT_NAME" => "/" }

  _, _, resp = Cuba.call(env)


  assert_response resp, ["123", "postal-service"]
end
