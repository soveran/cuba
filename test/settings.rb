require File.expand_path("helper", File.dirname(__FILE__))

test "settings contains request and response classes by default" do
  assert_equal Cuba.settings[:req], Rack::Request
  assert_equal Cuba.settings[:res], Cuba::Response
end

test "is inheritable and allows overriding" do
  Cuba.settings[:foo] = "bar"

  class Admin < Cuba; end

  assert_equal "bar", Admin.settings[:foo]

  Admin.settings[:foo] = "baz"

  assert_equal "bar", Cuba.settings[:foo]
  assert_equal "baz", Admin.settings[:foo]
end

test do
  Cuba.settings[:hello] = "Hello World"

  Cuba.define do
    on default do
      res.write settings[:hello]
    end
  end

  _, _, resp = Cuba.call({ "PATH_INFO" => "/", "SCRIPT_NAME" => ""})

  body = []

  resp.each do |line|
    body << line
  end

  assert_equal ["Hello World"], body
end

# The following tests the settings clone bug where
# we share the same reference. Deep cloning is the solution here.
Cuba.settings[:mote] ||= {}
Cuba.settings[:mote][:layout] ||= "layout"

class Login < Cuba
  settings[:mote][:layout] = "layout/guest"
end

test do
  assert Login.settings[:mote].object_id != Cuba.settings[:mote].object_id
end
