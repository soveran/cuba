require File.expand_path("helper", File.dirname(__FILE__))

class Shrimp
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, resp = @app.call(env)

    [status, headers, resp.body.reverse]
  end
end

test do
  API = Cuba.build
  API.use Shrimp
  API.define do
    on "v1/test" do
      res.write "OK"
      res.write "1"
      res.write "2"
    end
  end

  Cuba.define do
    on "api" do
      run API
    end
  end

  _, _, body = Cuba.call({ "PATH_INFO" => "/api/v1/test", "SCRIPT_NAME" => "/" })

  arr = []

  body.each do |line|
    arr << line
  end

  assert_equal ["2", "1", "OK"], arr
end