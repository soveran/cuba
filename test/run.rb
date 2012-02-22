require File.expand_path("helper", File.dirname(__FILE__))

test "redirect canonical example" do
  Cuba.define do
    def redirect(*args)
      run Cuba.new { on(true) { res.redirect(*args) }}
    end

    on "account" do
      redirect "/login", 307

      res.write "Super secure content"
    end
  end

  env = { "SCRIPT_NAME" => "/", "PATH_INFO" => "/account" }

  status, headers, resp = Cuba.call(env)

  assert_equal "/login", headers["Location"]
  assert_equal 307, status
  assert_response resp, []
end
