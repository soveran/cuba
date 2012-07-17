require File.expand_path("helper", File.dirname(__FILE__))

test "resetting" do
  old = Cuba.app
  assert old.object_id == Cuba.app.object_id

  Cuba.reset!
  assert old.object_id != Cuba.app.object_id
end

class Middle
  def initialize(app, first, second, &block)
    @app, @first, @second, @block = app, first, second, block
  end

  def call(env)
    env["m.first"] = @first
    env["m.second"] = @second
    env["m.block"] = @block.call

    @app.call(env)
  end
end

test "use passes in the arguments and block" do
  Cuba.use Middle, "First", "Second" do
    "this is the block"
  end

  Cuba.define do
    on get do
      on "hello" do
        "Default"
      end
    end
  end

  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/hello",
          "SCRIPT_NAME" => "/" }

  Cuba.call(env)

  assert "First" == env["m.first"]
  assert "Second" == env["m.second"]
  assert "this is the block" == env["m.block"]
end

test "reset and use" do
  Cuba.use Middle, "First", "Second" do
    "this is the block"
  end

  Cuba.define do
    on get do
      on "hello" do
        res.write "Default"
      end
    end
  end

  Cuba.reset!

  Cuba.use Middle, "1", "2" do
    "3"
  end

  Cuba.define do
    on get do
      on "hello" do
        res.write "2nd Default"
      end
    end
  end

  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/hello",
          "SCRIPT_NAME" => "/" }

  status, headers, resp = Cuba.call(env)

  assert 200 == status
  assert "text/html; charset=utf-8" == headers["Content-Type"]
  assert_response resp, ["2nd Default"]

  assert "1" == env["m.first"]
  assert "2" == env["m.second"]
  assert "3" == env["m.block"]
end

test "custom response" do
  class MyResponse < Cuba::Response
    def foobar
      write "Default"
    end
  end

  Cuba.settings[:res] = MyResponse

  Cuba.define do
    on get do
      on "hello" do
        res.foobar
      end
    end
  end

  env = { "REQUEST_METHOD" => "GET", "PATH_INFO" => "/hello",
          "SCRIPT_NAME" => "/" }

  status, headers, resp = Cuba.call(env)

  assert 200 == status
  assert "text/html; charset=utf-8" == headers["Content-Type"]
  assert_response resp, ["Default"]
end
