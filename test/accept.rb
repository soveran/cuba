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
