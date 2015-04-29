require_relative "helper"
require_relative "../lib/cuba/safe/csrf"

UnsafeRequest = Class.new(RuntimeError)

setup do
  Cuba.reset!

  Cuba.use(Rack::Session::Cookie, secret: "unsecure")

  Cuba.plugin(Cuba::Safe::CSRF)

  Driver.new(Cuba)
end

test "safe http methods" do |app|
  Cuba.define do
    raise UnsafeRequest if csrf.unsafe?
  end

  assert(app.get("/"))
  assert(app.head("/"))
end

test "invalid csrf param" do |app|
  Cuba.define do
    csrf.reset! if csrf.unsafe?

    on default do
      res.write(csrf.token)
    end
  end

  app.get("/")

  old_token = app.res.body

  app.post("/", "csrf_token" => "nonsense")

  new_token = app.res.body

  assert(old_token != new_token)
end

test "valid csrf param" do |app|
  Cuba.define do
    raise unless csrf.safe?

    get do
      res.write(csrf.token)
    end

    post do
      res.write("safe")
    end
  end

  app.get("/")

  csrf_token = app.res.body

  assert(!csrf_token.empty?)

  assert(app.post("/", "csrf_token" => csrf_token))
end

test "http header" do |app|
  csrf_token = SecureRandom.hex(32)

  Cuba.define do
    session[:csrf_token] = csrf_token
    raise if csrf.unsafe?
  end

  assert(app.post("/", {}, { "HTTP_X_CSRF_TOKEN" => csrf_token }))
end

test "sub app raises too" do |app|
  class App < Cuba
    define do
      post do
        res.write("unsafe")
      end
    end
  end

  Cuba.define do
    raise UnsafeRequest unless csrf.safe?

    on "app" do
      run(App)
    end
  end

  assert_raise(UnsafeRequest) do
    app.post("/app")
  end
end

test "only sub app" do |app|
  class App < Cuba
    define do
      raise UnsafeRequest unless csrf.safe?

      post do
        res.write("unsafe")
      end
    end
  end

  Cuba.define do
    on "app" do
      run(App)
    end

    on default do
      res.write("safe")
    end
  end

  assert(app.post("/"))

  assert_raise(UnsafeRequest) do
    app.post "/app"
  end
end
