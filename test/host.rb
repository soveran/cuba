require File.expand_path("helper", File.dirname(__FILE__))

test "matches a host" do
  Cuba.define do
    on host("example.com") do
      res.write "worked"
    end
  end

  env = { "HTTP_HOST" => "example.com" }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["worked"]
end

test "matches a host with a regexp" do
  Cuba.define do
    on host(/example/) do
      res.write "worked"
    end
  end

  env = { "HTTP_HOST" => "example.com" }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["worked"]
end
