require File.expand_path("helper", File.dirname(__FILE__))

setup do
  { "SCRIPT_NAME" => "/", "PATH_INFO" => "/about" }
end

test "one level path" do |env|
  Cuba.define do
    on path("about") do
      res.write "About"
    end
  end

  _, _, resp = Cuba.call(env)

  assert_equal ["About"], resp.body
  assert_equal({ "SCRIPT_NAME" => "/", "PATH_INFO" => "/about" }, env)
end

test "two level nested paths" do |env|
  Cuba.define do
    on path("about") do
      on path("1") do
        res.write "+1"
      end

      on path("2") do
        res.write "+2"
      end
    end
  end

  env["PATH_INFO"] = "/about/1"

  _, _, resp = Cuba.call(env)

  assert_equal ["+1"], resp.body

  env["PATH_INFO"] = "/about/2"

  _, _, resp = Cuba.call(env)

  assert_equal ["+2"], resp.body
end

test "two level inlined paths" do |env|
  Cuba.define do
    on path("a"), path("b") do
      res.write "a"
      res.write "b"
    end
  end

  env["PATH_INFO"] = "/a/b"

  _, _, resp = Cuba.call(env)

  assert_equal ["a", "b"], resp.body
end

test "a path with some regex captures" do |env|
  Cuba.define do
    on path("user(\\d+)") do |uid|
      res.write uid
    end
  end

  env["PATH_INFO"] = "/user123"

  _, _, resp = Cuba.call(env)

  assert_equal ["123"], resp.body
end

test "matching the root" do |env|
  Cuba.define do
    on path("") do
      res.write "Home"
    end
  end

  env["PATH_INFO"] = "/"

  _, _, resp = Cuba.call(env)

  assert_equal ["Home"], resp.body
end
