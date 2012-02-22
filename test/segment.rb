require File.expand_path("helper", File.dirname(__FILE__))

setup do
  Cuba.define do
    on "post" do
      on :id do |id|
        res.write id
      end
    end
  end

  { "SCRIPT_NAME" => "/", "PATH_INFO" => "/post" }
end

test "matches numeric ids" do |env|
  env["PATH_INFO"] += "/1"

  _, _, resp = Cuba.call(env)

  assert_response resp, ["1"]
end

test "matches decimal numbers" do |env|
  env["PATH_INFO"] += "/1.1"

  _, _, resp = Cuba.call(env)

  assert_response resp, ["1.1"]
end

test "matches slugs" do |env|
  env["PATH_INFO"] += "/my-blog-post-about-cuba"

  _, _, resp = Cuba.call(env)

  assert_response resp, ["my-blog-post-about-cuba"]
end

test "matches only the first segment available" do |env|
  env["PATH_INFO"] += "/one/two/three"

  _, _, resp = Cuba.call(env)

  assert_response resp, ["one"]
end
