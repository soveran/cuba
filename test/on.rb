require File.expand_path("helper", File.dirname(__FILE__))

test "executes on true" do
  Cuba.define do
    on true do
      res.write "+1"
    end
  end

  _, _, resp = Cuba.call({})

  assert_equal ["+1"], resp.body
end

test "executes on non-false" do
  Cuba.define do
    on "123" do
      res.write "+1"
    end
  end

  _, _, resp = Cuba.call({})

  assert_equal ["+1"], resp.body
end

test "restores SCRIPT_NAME and PATH_INFO" do
  Cuba.define do
    on true do
      env["SCRIPT_NAME"] = "foo"
      env["PATH_INFO"] = "/hello"

      raise "Something went wrong"
    end
  end

  env = { "SCRIPT_NAME" => "/", "PATH_INFO" => "/hello" }

  begin
    _, _, resp = Cuba.call(env)
  rescue
  end

  assert_equal "/", env["SCRIPT_NAME"]
  assert_equal "/hello", env["PATH_INFO"]
end

test "ensures SCRIPT_NAME and PATH_INFO are reverted" do
  Cuba.define do
    on lambda { env["SCRIPT_NAME"] = "/hello"; false } do
      res.write "Unreachable"
    end
  end

  env = { "SCRIPT_NAME" => "/", "PATH_INFO" => "/hello" }

  _, _, resp = Cuba.call(env)

  assert_equal "/", env["SCRIPT_NAME"]
  assert_equal "/hello", env["PATH_INFO"]
  assert_equal [], resp.body
end

test "skips consecutive matches" do
  Cuba.define do
    on true do
      env["foo"] = "foo"

      res.write "foo"
    end

    on true do
      env["bar"] = "bar"

      res.write "bar"
    end
  end

  env = {}

  _, _, resp = Cuba.call(env)

  assert_equal "foo", env["foo"]
  assert_equal ["foo"], resp.body

  assert ! env["bar"]
end

test "finds first match available" do
  Cuba.define do
    on false do
      res.write "foo"
    end

    on true do
      res.write "bar"
    end
  end

  _, _, resp = Cuba.call({})

  assert_equal ["bar"], resp.body
end
