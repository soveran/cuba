require File.expand_path("helper", File.dirname(__FILE__))

setup do
  { "SCRIPT_NAME" => "/", "PATH_INFO" => "/about" }
end

test "one level path" do |env|
  Cuba.define do
    on "about" do
      res.write "About"
    end
  end

  _, _, resp = Cuba.call(env)

  assert_response resp, ["About"]
end

test "two level nested paths" do |env|
  Cuba.define do
    on "about" do
      on "1" do
        res.write "+1"
      end

      on "2" do
        res.write "+2"
      end
    end
  end

  env["PATH_INFO"] = "/about/1"

  _, _, resp = Cuba.call(env)

  assert_response resp, ["+1"]

  env["PATH_INFO"] = "/about/2"

  _, _, resp = Cuba.call(env)

  assert_response resp, ["+2"]
end

test "two level inlined paths" do |env|
  Cuba.define do
    on "a/b" do
      res.write "a"
      res.write "b"
    end
  end

  env["PATH_INFO"] = "/a/b"

  _, _, resp = Cuba.call(env)

  assert_response resp, ["a", "b"]
end

test "a path with some regex captures" do |env|
  Cuba.define do
    on "user(\\d+)" do |uid|
      res.write uid
    end
  end

  env["PATH_INFO"] = "/user123"

  _, _, resp = Cuba.call(env)

  assert_response resp, ["123"]
end

test "matching the root" do |env|
  Cuba.define do
    on "" do
      res.write "Home"
    end
  end

  env["PATH_INFO"] = "/"

  _, _, resp = Cuba.call(env)

  assert_response resp, ["Home"]
end
