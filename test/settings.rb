require File.expand_path("helper", File.dirname(__FILE__))

test "settings is an empty hash by default" do
  assert Cuba.settings.kind_of?(Hash)
  assert Cuba.settings.empty?
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
