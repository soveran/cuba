require File.expand_path("helper", File.dirname(__FILE__))

test "chunked response using an Enumerable" do
  app = Cuba.new do
    on root do
      lines = %w(foo bar)

      res.chunked(lines)
    end
  end

  env = { "SCRIPT_NAME" => "/", "PATH_INFO" => "/" }

  status, headers, body = app.call(env)

  assert_equal status, 200

  assert_equal headers, {
    "Content-Type" => "text/html; charset=utf-8",
    "Transfer-Encoding" => "chunked" }

  assert_equal body.to_a, %w(foo bar)
end

test "chunked response using a block" do
  app = Cuba.new do
    on root do
      res.chunked do |body|
        body << "foo"
        body << "bar"
      end
    end
  end

  env = { "SCRIPT_NAME" => "/", "PATH_INFO" => "/" }

  status, headers, body = app.call(env)

  assert_equal status, 200

  assert_equal headers, {
    "Content-Type" => "text/html; charset=utf-8",
    "Transfer-Encoding" => "chunked" }

  assert_equal body.to_a, %w(foo bar)
end
