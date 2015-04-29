require_relative "helper"

module Helper
  def clean(str)
    return str.strip
  end

  module Number
    def one
      return 1
    end
  end

  def self.setup(app)
    app.plugin(Number)
  end

  module ClassMethods
    def foo
      "foo"
    end
  end
end

setup do
  Cuba.plugin(Helper)

  Driver.new(Cuba)
end

test "plugin" do |app|
  Cuba.define do
    get do
      res.write(clean(" foo "))
    end
  end

  app.get("/")

  assert_equal "foo", app.res.body
end

test "class methods" do |app|
  assert_equal "foo", Cuba.foo
end

test "setup" do |app|
  Cuba.define do
    res.write(one)
  end

  app.get("/")

  assert_equal "1", app.res.body
end
