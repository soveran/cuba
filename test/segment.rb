require File.expand_path("helper", File.dirname(__FILE__))

setup do
  Cuba.define do
    on path("post") do
      on segment do |id|
        res.write id
      end
    end
  end

  { "SCRIPT_NAME" => "/", "PATH_INFO" => "/post" }
end

test "matches numeric ids" do |env|
  env["PATH_INFO"] += "/1"

  _, _, resp = Cuba.call(env)

  assert_equal ["1"], resp.body
end

test "matches decimal numbers" do |env|
  env["PATH_INFO"] += "/1.1"

  _, _, resp = Cuba.call(env)

  assert_equal ["1.1"], resp.body
end

test "matches slugs" do |env|
  env["PATH_INFO"] += "/my-blog-post-about-cuba"

  _, _, resp = Cuba.call(env)

  assert_equal ["my-blog-post-about-cuba"], resp.body
end

test "matches only the first segment available" do |env|
  env["PATH_INFO"] += "/one/two/three"

  _, _, resp = Cuba.call(env)

  assert_equal ["one"], resp.body
end
