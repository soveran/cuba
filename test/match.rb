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

  assert_response resp, ["123"]
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

  assert_response resp, ["jdoe", "123"]
end

test "regex nesting" do |env|
  Cuba.define do
    on(/u\/(\w+)/) do |uid|
      res.write uid

      on(/posts\/(\d+)/) do |id|
        res.write id
      end
    end
  end

  env["PATH_INFO"] = "/u/jdoe/posts/123"

  _, _, resp = Cuba.call(env)

  assert_response resp, ["jdoe", "123"]
end

test "regex nesting colon param style" do |env|
  Cuba.define do
    on(/u:(\w+)/) do |uid|
      res.write uid

      on(/posts:(\d+)/) do |id|
        res.write id
      end
    end
  end

  env["PATH_INFO"] = "/u:jdoe/posts:123"

  _, _, resp = Cuba.call(env)

  assert_response resp, ["jdoe", "123"]
end

test "symbol matching" do |env|
  Cuba.define do
    on "user", :id do |uid|
      res.write uid

      on "posts", :pid do |id|
        res.write id
      end
    end
  end

  env["PATH_INFO"] = "/user/jdoe/posts/123"

  _, _, resp = Cuba.call(env)

  assert_response resp, ["jdoe", "123"]
end
