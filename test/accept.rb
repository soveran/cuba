require File.expand_path("helper", File.dirname(__FILE__))

test "accept mimetypes" do
  Cuba.define do
    on accept("application/xml") do
      res.write res["Content-Type"]
    end
  end

  env = { "HTTP_ACCEPT" => "application/xml",
          "SCRIPT_NAME" => "/", "PATH_INFO" => "/post" }

   _, _, body = Cuba.call(env)

  assert_response body, ["application/xml"]
end

test "tests don't fail when you don't specify an accept type" do
  Cuba.define do
    on accept("application/xml") do
      res.write res["Content-Type"]
    end

    on default do
      res.write "Default action"
    end
  end

  _, _, body = Cuba.call({})

  assert_response body, ["Default action"]
end

test "accept HTML mimetype" do
  Cuba.define do
    on accept("text/html") do
      res.write Cuba::Response::ContentType::HTML
    end
  end

  env = { "HTTP_ACCEPT" => "text/html",
          "SCRIPT_NAME" => "/", "PATH_INFO" => "/post" }

   _, _, body = Cuba.call(env)

  assert_response body, ["text/html"]
end

test "accept TEXT mimetype" do
  Cuba.define do
    on accept("text/plain") do
      res.write Cuba::Response::ContentType::TEXT
    end
  end

  env = { "HTTP_ACCEPT" => "text/plain",
          "SCRIPT_NAME" => "/", "PATH_INFO" => "/post" }

   _, _, body = Cuba.call(env)

  assert_response body, ["text/plain"]
end

test "accept JSON mimetype" do
  Cuba.define do
    on accept("application/json") do
      res.write Cuba::Response::ContentType::JSON
    end
  end

  env = { "HTTP_ACCEPT" => "application/json",
          "SCRIPT_NAME" => "/", "PATH_INFO" => "/get" }

   _, _, body = Cuba.call(env)

  assert_response body, ["application/json"]
end
