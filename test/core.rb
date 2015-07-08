require_relative "helper"

setup do
  Driver.new(Cuba)
end

test "hello world" do |app|
  Cuba.define do
    get do
      res.write("hello world")
    end

    on "foo" do
      run Foo, foo: 42
    end
  end

  app.get("/")

  assert_equal 200, app.res.status
  assert_equal "hello world", app.res.body
end

test "capturing" do |app|
  Cuba.define do
    on :id do
      res.write inbox[:id]
    end
  end

  app.get("/42")

  assert_equal 200, app.res.status
  assert_equal "42", app.res.body
end

test "inbox passing" do |app|
  class Foo < Cuba
    define do
      get do
        res.write(inbox[:foo])
      end
    end
  end

  Cuba.define do
    on "foo" do
      run Foo, foo: 42
    end
  end

  app.get("/foo")

  assert_equal 200, app.res.status
  assert_equal "42", app.res.body
end
