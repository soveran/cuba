require File.expand_path("helper", File.dirname(__FILE__))

test "executes on true" do
  Cuba.define do
    on "foo/:i" do |i|
      res.write render("test/test.erb", title: i)
    end
  end

  1000.times do |i|
    _, _, resp = Cuba.call({ "PATH_INFO" => "/foo/#{i}", "SCRIPT_NAME" => "" })
  end

  assert_equal 1, Thread.current[:_cache].instance_variable_get(:@cache).size
end