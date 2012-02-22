require File.expand_path("helper", File.dirname(__FILE__))

test "executes on true" do
  Cuba.define do
    on true do
      res.write "+1"
    end
  end

  _, _, resp = Cuba.call({})

  assert_response resp, ["+1"]
end

test "executes on non-false" do
  Cuba.define do
    on "123" do
      res.write "+1"
    end
  end

  _, _, resp = Cuba.call({ "PATH_INFO" => "/123", "SCRIPT_NAME" => "/" })

  assert_response resp, ["+1"]
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
  assert_response resp, []
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
  assert_response resp, ["foo"]

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

  assert_response resp, ["bar"]
end

test "reverts a half-met matcher" do
  Cuba.define do
    on "post", false do
      res.write "Should be unmet"
    end
  end

  env = { "PATH_INFO" => "/post", "SCRIPT_NAME" => "/" }
  _, _, resp = Cuba.call(env)

  assert_response resp, []
  assert_equal "/post", env["PATH_INFO"]
  assert_equal "/", env["SCRIPT_NAME"]
end
