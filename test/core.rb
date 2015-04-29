require_relative "helper"

setup do
  Driver.new(Cuba)
end

test "hello world" do |app|
  Cuba.define do
    get do
      res.write("hello world")
    end
  end

  app.get("/")

  assert_equal 200, app.res.status
  assert_equal "hello world", app.res.body
end
