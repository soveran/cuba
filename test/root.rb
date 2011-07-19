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
  
  assert_equal ["/"], resp.body
end

test "nested empty segments" do
  Cuba.define do
    on "" do
      on "" do
        on "1" do
          res.write "IT WORKS!"
        end
      end
    end
  end
      
  env = {
    "SCRIPT_NAME" => "",
    "PATH_INFO" => "///1"
  }

  _, _, resp = Cuba.call(env)
  
  assert_equal ["IT WORKS!"], resp.body
end
