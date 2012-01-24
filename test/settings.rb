require_relative "helper"

Cuba.plugin Cuba::Settings
Cuba.set :foo, "bar"

test do
  Cuba.define do
    on default do
      res.write settings.foo
    end
  end

  _, _, body = Cuba.call({})

  assert_response body, ["bar"]
end

test do
  assert_equal "bar", Cuba.foo
end

class Admin < Cuba
end

test do
  assert_equal "bar", Admin.foo

  Admin.foo = "baz"

  assert_equal "baz", Admin.foo
  assert_equal "bar", Cuba.foo
end

test do
  Cuba.foo = "baz"
  assert_equal "baz", Cuba.foo
end
