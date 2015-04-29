require_relative "helper"

class Shrimp
  def initialize(app)
    @app = app
  end

  def call(env)
    s, h, resp = @app.call(env)

    return [s, h, resp.reverse]
  end
end

setup do
  Driver.new(Cuba)
end

test "use middleware in main application" do |app|
  Cuba.use(Shrimp)

  class API < Cuba
  end

  API.define do
    get do
      res.write("2")
      res.write("1")
    end
  end

  Cuba.define do
    on "api" do
      run(API)
    end

    get do
      res.write("1")
      res.write("2")
    end
  end

  app.get("/")

  assert_equal 200, app.res.status
  assert_equal "21", app.res.body
end

test "use middleware in child application" do
  Cuba.define do
    run(API)
  end

  class API < Cuba
    use(Shrimp)
  end

  API.define do
    get do
      res.write("1")
      res.write("2")
    end
  end

  app = Driver.new(Cuba)

  app.get("/")

  assert_equal 200, app.res.status
  assert_equal "21", app.res.body
end
