require_relative "helper"

require "cuba/render"

test "doesn't override the settings if they already exist" do
  Cuba.settings[:render] = {
    :views => "./test/views",
    :template_engine => "haml"
  }

  Cuba.plugin Cuba::Render

  assert_equal "./test/views", Cuba.settings[:render][:views]
  assert_equal "haml", Cuba.settings[:render][:template_engine]
end

scope do
  setup do
    Cuba.plugin Cuba::Render
    Cuba.settings[:render][:views] = "./test/views"
    Cuba.settings[:render][:template_engine] = "erb"

    Cuba.define do
      on "home" do
        res.write view("home", name: "Agent Smith", title: "Home")
      end

      on "about" do
        res.write partial("about", title: "About Cuba")
      end

      on "inline" do
        template = "Hello <%= name %>"
        res.write render(template, {name: "Agent Smith"}, :template_block=>proc{template})
      end
    end
  end

  test "partial" do
    _, _, body = Cuba.call({ "PATH_INFO" => "/about", "SCRIPT_NAME" => "/" })

    assert_response body, ["<h1>About Cuba</h1>\n"]
  end

  test "view" do
    _, _, body = Cuba.call({ "PATH_INFO" => "/home", "SCRIPT_NAME" => "/" })

    assert_response body, ["<title>Cuba: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>\n"]
  end

  test "inline render" do
    _, _, body = Cuba.call({ "PATH_INFO" => "/inline", "SCRIPT_NAME" => "/" })

    assert_response body, ["Hello Agent Smith"]
  end

  test "partial with str as engine" do
    Cuba.settings[:render][:template_engine] = "str"

    _, _, body = Cuba.call({ "PATH_INFO" => "/about", "SCRIPT_NAME" => "/" })

    assert_response body, ["<h1>About Cuba</h1>\n"]
  end

  test "view with str as engine" do
    Cuba.settings[:render][:template_engine] = "str"

    _, _, body = Cuba.call({ "PATH_INFO" => "/home", "SCRIPT_NAME" => "/" })

    assert_response body, ["<title>Cuba: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>\n\n"]
  end

  test "custom default layout support" do
    Cuba.settings[:render][:layout] = "layout-alternative"

    _, _, body = Cuba.call({ "PATH_INFO" => "/home", "SCRIPT_NAME" => "/" })

    assert_response body, ["<title>Alternative Layout: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>\n"]
  end
end

test "caching behavior" do
  Thread.current[:_cache] = nil

  Cuba.plugin Cuba::Render
  Cuba.settings[:render][:views] = "./test/views"

  Cuba.define do
    on "foo/:i" do |i|
      res.write partial("test", title: i)
    end
  end

  10.times do |i|
    _, _, resp = Cuba.call({ "PATH_INFO" => "/foo/#{i}", "SCRIPT_NAME" => "" })
  end

  assert_equal 1, Thread.current[:_cache].instance_variable_get(:@cache).size
end

test "simple layout support" do
  Cuba.plugin Cuba::Render

  Cuba.define do
    on true do
      res.write render("test/views/layout-yield.erb") {
        render("test/views/content-yield.erb")
      }
    end
  end

  _, _, resp = Cuba.call({})

  assert_response resp, ["Header\nThis is the actual content.\nFooter\n"]
end

test "overrides layout" do
  Cuba.plugin Cuba::Render
  Cuba.settings[:render][:views] = "./test/views"

  Cuba.define do
    on true do
      res.write view("home", { name: "Agent Smith", title: "Home" }, "layout-alternative")
    end
  end

  _, _, body = Cuba.call({})

  assert_response body, ["<title>Alternative Layout: Home</title>\n<h1>Home</h1>\n<p>Hello Agent Smith</p>\n"]
end
