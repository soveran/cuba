require File.expand_path("helper", File.dirname(__FILE__))

def consume_chunks(body)
  result = []

  body.each { |part| result << part[/\A\d+\r\n(.+?)\r\n\Z/, 1] }

  result[0..-2]
end

test "chunked response using an Enumerable" do
  Cuba.use Rack::Chunked # Added by supported servers.

  Cuba.define do
    on root do
      lines = %w(foo bar)

      res.chunked(lines)
    end
  end

  env = { "SCRIPT_NAME" => "/", "PATH_INFO" => "/" }

  status, headers, body = Cuba.call(env)

  assert_equal status, 200

  assert_equal headers, {
    "Content-Type" => "text/html; charset=utf-8",
    "Transfer-Encoding" => "chunked" }

  assert_equal consume_chunks(body), %w(foo bar)
end

test "chunked response using a block" do
  Cuba.use Rack::Chunked # Added by supported servers.

  Cuba.define do
    on root do
      res.chunked do |body|
        body << "foo"
        body << "bar"
      end
    end
  end

  env = { "SCRIPT_NAME" => "/", "PATH_INFO" => "/" }

  status, headers, body = Cuba.call(env)

  assert_equal status, 200

  assert_equal headers, {
    "Content-Type" => "text/html; charset=utf-8",
    "Transfer-Encoding" => "chunked" }

  assert_equal consume_chunks(body), %w(foo bar)
end
