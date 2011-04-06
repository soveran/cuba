require File.expand_path("helper", File.dirname(__FILE__))

test "executes on true" do
  Cuba.define do
    on true do
      res.write render("layouting_layout.haml") {
        render("layouting_content.haml")
      }
    end
  end

  _, _, resp = Cuba.call({})

  assert_equal ["alfa\nbeta\n"], resp.body
end
