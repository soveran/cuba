require File.expand_path("helper", File.dirname(__FILE__))

setup do
  { "SCRIPT_NAME" => "/", "PATH_INFO" => "/about/1/2" }
end

test "paths and numbers" do |env|
  Cuba.define do
    on path("about") do
      on number, number do |one, two|
        res.write one
        res.write two
      end
    end
  end

  _, _, resp = Cuba.call(env)

  assert_equal ["1", "2"], resp.body
end

test "paths and decimals" do |env|
  Cuba.define do
    on path("about") do
      on number do |one|
        res.write one
      end
    end
  end

  env["PATH_INFO"] = "/about/1.2"

  _, _, resp = Cuba.call(env)

  assert_equal [], resp.body
end
