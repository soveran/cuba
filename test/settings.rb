require File.expand_path("helper", File.dirname(__FILE__))

test "use settings inside the application" do
  Cuba.settings[:message] = "hello"
  Cuba.define do
    get do
      res.write(settings[:message])
    end
  end

  app = Driver.new(Cuba)
  app.get("/")

  assert_equal "hello", app.res.body
end

test "settings are inheritable and overridable" do
  Cuba.settings[:foo] = "bar"

  class Admin < Cuba; end

  assert_equal "bar", Admin.settings[:foo]

  Admin.settings[:foo] = "baz"

  assert_equal "bar", Cuba.settings[:foo]
  assert_equal "baz", Admin.settings[:foo]
end
