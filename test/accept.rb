require File.expand_path("helper", File.dirname(__FILE__))

test "accept mimetypes" do
  Cuba.define do
    on accept("application/xml") do
      res.write res["Content-Type"]
    end
  end

  env = { "HTTP_ACCEPT" => "application/xml", 
          "SCRIPT_NAME" => "/", "PATH_INFO" => "/post" }

   _, _, resp = Cuba.call(env)

  assert_equal ["application/xml"], resp.body
end
