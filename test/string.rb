require File.expand_path("helper", File.dirname(__FILE__))

setup do
  { "SCRIPT_NAME" => "/", "PATH_INFO" => "/posts/123" }
end

test "text-book example" do |env|
  Cuba.define do
    on "posts/:id" do |id|
      res.write id
    end
  end

  _, _, resp = Cuba.call(env)

  assert_equal ["123"], resp.body
end

test "multi-param" do |env|
  Cuba.define do
    on "u/:uid/posts/:id" do |uid, id|
      res.write uid
      res.write id
    end
  end

  env["PATH_INFO"] = "/u/jdoe/posts/123"

  _, _, resp = Cuba.call(env)

  assert_equal ["jdoe", "123"], resp.body
end