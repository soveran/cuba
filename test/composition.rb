require File.expand_path("helper", File.dirname(__FILE__))

test "composing on top of a PATH" do
  Services = Cuba.new do
    on "services/:id" do |id|
      res.write "View #{id}"
    end
  end

  Cuba.define do
    on "provider" do
      run Services
    end
  end

  env = { "SCRIPT_NAME" => "/", "PATH_INFO" => "/provider/services/101" }

   _, _, resp = Cuba.call(env)

   assert_response resp, ["View 101"]
end

test "redefining not_found" do
  class Users < Cuba
    def not_found
      res.status = 404
      res.write "Not found!"
    end

    define do
      on root do
        res.write "Users"
      end
    end
  end

  class Cuba
    def not_found
      res.status = 404
      res.write "Error 404"
    end
  end

  Cuba.define do
    on "users" do
      run Users
    end
  end

  env = { "SCRIPT_NAME" => "/", "PATH_INFO" => "/users" }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["Users"]

  env = { "SCRIPT_NAME" => "/", "PATH_INFO" => "/users/42" }

  status, _, resp = Cuba.call(env)

  assert_response resp, ["Not found!"]
  assert_equal status,  404

  env = { "SCRIPT_NAME" => "/", "PATH_INFO" => "/guests" }

  status, _, resp = Cuba.call(env)

  assert_response resp, ["Error 404"]
  assert_equal status,  404
end

test "multi mount" do
  A = Cuba.new do
    on "a" do
      res.write "View a"
    end
  end

  B = Cuba.new do
    on "b" do
      res.write "View b"
    end
  end

  class Cuba
    def mount(app)
      result = app.call(req.env)
      halt result if result[0] != 404
    end
  end

  Cuba.define do
    on default do
      mount A 
      mount B
    end
  end

  env = { "SCRIPT_NAME" => "/", "PATH_INFO" => "/b" }

   _, _, resp = Cuba.call(env)

   assert_response resp, ["View b"]
end
