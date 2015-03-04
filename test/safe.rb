require_relative "helper"
require "cuba/safe"

scope do
  test "secure headers" do
    Cuba.plugin(Cuba::Safe)

    class Hello < Cuba
      define do
        on root do
          res.write("hello")
        end
      end
    end

    Cuba.define do
      on root do
        res.write("home")
      end

      on "hello" do
        run(Hello)
      end
    end

    secure_headers = Cuba::Safe::SecureHeaders::HEADERS

    _, headers, _ = Cuba.call("PATH_INFO" => "/", "SCRIPT_NAME" => "/")
    secure_headers.each do |header, value|
      assert_equal(value, headers[header])
    end

    _, headers, _ = Cuba.call("PATH_INFO" => "/hello", "SCRIPT_NAME" => "/")
    secure_headers.each do |header, value|
      assert_equal(value, headers[header])
    end
  end

  test "secure headers only in sub app" do
    Cuba.settings[:default_headers] = {}

    class About < Cuba
      plugin(Cuba::Safe)

      define do
        on root do
          res.write("about")
        end
      end
    end

    Cuba.define do
      on root do
        res.write("home")
      end

      on "about" do
        run(About)
      end
    end

    secure_headers = Cuba::Safe::SecureHeaders::HEADERS

    _, headers, _ = Cuba.call("PATH_INFO" => "/", "SCRIPT_NAME" => "/")
    secure_headers.each do |header, _|
      assert(!headers.key?(header))
    end

    _, headers, _ = Cuba.call("PATH_INFO" => "/about", "SCRIPT_NAME" => "/")
    secure_headers.each do |header, value|
      assert_equal(value, headers[header])
    end
  end
end
