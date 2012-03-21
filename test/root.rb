require File.expand_path("helper", File.dirname(__FILE__))

test "matching an empty segment" do
  Cuba.define do
    on "" do
      res.write req.path
    end
  end

  env = {
    "SCRIPT_NAME" => "",
    "PATH_INFO" => "/"
  }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["/"]
end

test "nested empty segments" do
  Cuba.define do
    on "" do
      on "" do
        on "1" do
          res.write "IT WORKS!"
          res.write req.path
        end
      end
    end
  end

  env = {
    "SCRIPT_NAME" => "",
    "PATH_INFO" => "///1"
  }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["IT WORKS!", "///1"]
end

test "/events/? scenario" do
  class Events < Cuba
    define do
      on root do
        res.write "Hooray"
      end
    end
  end

  Cuba.define do
    on "events" do
      run Events
    end
  end

  env = {
    "SCRIPT_NAME" => "",
    "PATH_INFO" => "/events"
  }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["Hooray"]

  env = {
    "SCRIPT_NAME" => "",
    "PATH_INFO" => "/events/"
  }

  _, _, resp = Cuba.call(env)

  assert_response resp, ["Hooray"]

  env = {
    "SCRIPT_NAME" => "",
    "PATH_INFO" => "/events/a"
  }

  _, _, resp = Cuba.call(env)

  assert_response resp, []
end
