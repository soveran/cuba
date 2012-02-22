require File.expand_path("helper", File.dirname(__FILE__))

setup do
  Cuba.define do
    on "styles" do
      on extension("css") do |file|
        res.write file
      end
    end
  end

  { "SCRIPT_NAME" => "/", "PATH_INFO" => "/styles" }
end

test "/styles/reset.css" do |env|
  env["PATH_INFO"] += "/reset.css"

  _, _, resp = Cuba.call(env)

  assert_response resp, ["reset"]
end
