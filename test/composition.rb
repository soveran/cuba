require File.expand_path("helper", File.dirname(__FILE__))

test "composing on top of a PATH" do
  Services = Cuba.new {
    on "services/:id" do |id|
      res.write "View #{id}"
    end
  }

  Cuba.define do
    on "provider" do
      run Services
    end
  end

  env = { "SCRIPT_NAME" => "/", "PATH_INFO" => "/provider/services/101" }

   _, _, resp = Cuba.call(env)

   assert_response resp, ["View 101"]
end
