require File.expand_path("helper", File.dirname(__FILE__))

test "simple layout support" do
  Cuba.define do
    on true do
      res.write render("test/fixtures/layout.erb") {
        render("test/fixtures/content.erb")
      }
    end
  end

  _, _, resp = Cuba.call({})

  assert_equal ["alfa beta\n\n"], resp.body
end
