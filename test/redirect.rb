require File.expand_path("helper", File.dirname(__FILE__))

test "redirect" do
  Cuba.define do
    on "hello" do
      res.write "hello, world"
    end

    on "" do
      res.redirect "/hello"
    end
  end

  env = { "SCRIPT_NAME" => "/", "PATH_INFO" => "/" }

  status, headers, body = Cuba.call(env)

  assert_equal status, 302
  assert_equal headers, {
    "Content-Type" => "text/html; charset=utf-8",
    "Location" => "/hello" }
  assert_response body, []
end
