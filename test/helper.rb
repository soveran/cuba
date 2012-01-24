$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require "cuba"

prepare { Cuba.reset! }

def assert_response(body, expected)
  arr = []
  body.each { |line| arr << line }

  assert_equal arr, expected
end