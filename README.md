Cuba
====

_n_. a microframework for web development.

![Cuba and Rum, by Jan Sochor](http://farm3.static.flickr.com/2619/4032103097_8324c6fecf.jpg)

Community
---------

Meet us on IRC: [#cuba.rb](irc://chat.freenode.net/#cuba.rb) on [freenode.net](http://freenode.net/)

Description
-----------

Cuba is a microframework for web development originally inspired by [Rum][rum],
a tiny but powerful mapper for [Rack][rack] applications.

It integrates many templates via [Tilt][tilt], and testing via
[Cutest][cutest] and [Capybara][capybara].

[rum]: http://github.com/chneukirchen/rum
[rack]: http://github.com/chneukirchen/rack
[tilt]: http://github.com/rtomayko/tilt
[cutest]: http://github.com/djanowski/cutest
[capybara]: http://github.com/jnicklas/capybara

Usage
-----

Here's a simple application:

``` ruby
# cat hello_world.rb
require "cuba"

Cuba.use Rack::Session::Cookie

Cuba.define do
  on get do
    on "hello" do
      res.write "Hello world!"
    end

    on root do
      res.redirect "/hello"
    end
  end
end

# cat hello_world_test.rb
require "cuba/test"

scope do
  test "Homepage" do
    visit "/"
    assert has_content?("Hello world!")
  end
end
```

To run it, you can create a `config.ru` file:

``` ruby
# cat config.ru
require "./hello_world"

run Cuba
```

You can now run `rackup` and enjoy what you have just created.

Matchers
--------

Here's an example showcasing how different matchers work:

``` ruby
require "cuba"

Cuba.use Rack::Session::Cookie

Cuba.define do

  # only GET requests
  on get do

    # /
    on root do
      res.write "Home"
    end

    # /about
    on "about" do
      res.write "About"
    end

    # /styles/basic.css
    on "styles", extension("css") do |file|
      res.write "Filename: #{file}" #=> "Filename: basic"
    end

    # /post/2011/02/16/hello
    on "post/:y/:m/:d/:slug" do |y, m, d, slug|
      res.write "#{y}-#{m}-#{d} #{slug}" #=> "2011-02-16 hello"
    end

    # /username/foobar
    on "username/:username" do |username|
      user = User.find_by_username(username) # username == "foobar"

      # /username/foobar/posts
      on "posts" do

        # You can access `user` here, because the `on` blocks
        # are closures.
        res.write "Total Posts: #{user.posts.size}" #=> "Total Posts: 6"
      end

      # /username/foobar/following
      on "following" do
        res.write user.following.size #=> "1301"
      end
    end

    # /search?q=barbaz
    on "search", param("q") do |query|
      res.write "Searched for #{query}" #=> "Searched for barbaz"
    end
  end

  # only POST requests
  on post do
    on "login" do

      # POST /login, user: foo, pass: baz
      on param("user"), param("pass") do |user, pass|
        res.write "#{user}:#{pass}" #=> "foo:baz"
      end

      # If the params `user` and `pass` are not provided, this block will
      # get executed.
      on true do
        res.write "You need to provide user and pass!"
      end
    end
  end
end
```

Security
--------

The favorite security layer for Cuba is
[Rack::Protection](https://github.com/rkh/rack-protection). It is not
included by default because there are legitimate uses for plain Cuba
(for instance, when designing an API).

If you are building a web application, by all means make sure to
include a security layer. As it is the convention for unsafe
operations, only POST, PUT and DELETE requests are monitored.

``` ruby
require "cuba"
require "rack/protection"

Cuba.use Rack::Session::Cookie
Cuba.use Rack::Protection
Cuba.use Rack::Protection::RemoteReferrer

Cuba.define do

  # Now your app is protected against a wide range of attacks.
  ...
end
```

HTTP Verbs
----------

There are four matchers defined for HTTP Verbs: `get`, `post`, `put` and
`delete`. But the world doesn't end there, does it? As you have the whole
request available via the `req` object, you can query it with helper methods
like `req.options?` or `req.head?`, or you can even go to a lower level
and inspect the environment via the `env` object, and check for example if
`env["REQUEST_METHOD"]` equals the obscure verb `PATCH`.

What follows is an example of different ways of saying the same thing:

``` ruby
on env["REQUEST_METHOD"] == "GET", "api" do ... end

on req.get?, "api" do ... end

on get, "api" do ... end
```

Actually, `get` is syntax sugar for `req.get?`, which in turn is syntax sugar
for `env["REQUEST_METHOD"] == "GET"`.

Request and Response
--------------------

You may have noticed we use `req` and `res` a lot. Those variables are
instances of [Rack::Request][request] and `Cuba::Response` respectively, and
`Cuba::Response` is just an optimized version of
[Rack::Response][response].

[request]: http://rack.rubyforge.org/doc/classes/Rack/Request.html
[response]: http://rack.rubyforge.org/doc/classes/Rack/Response.html

Those objects are helpers for accessing the request and for building
the response. Most of the time, you will just use `req.write`.

If you want to use custom `Request` or `Response` objects, you can
set the new values as follows:

``` ruby
Cuba.settings[:req] = MyRequest
Cuba.settings[:res] = MyResponse
```

Make sure to provide classes compatible with those from Rack.

Captures
--------

You may have noticed that some matchers yield a value to the block. The rules
for determining if a matcher will yield a value are simple:

1. Regex captures: `"posts/(\\d+)-(.*)"` will yield two values, corresponding to each capture.
2. Placeholders: `"users/:id"` will yield the value in the position of :id.
3. Symbols: `:foobar` will yield if a segment is available.
4. File extensions: `extension("css")` will yield the basename of the matched file.
5. Parameters: `param("user")` will yield the value of the parameter user, if present.

The first case is important because it shows the underlying effect of regex
captures.

In the second case, the substring `:id` gets replaced by `([^\\/]+)` and the
string becomes `"users/([^\\/]+)"` before performing the match, thus it reverts
to the first form we saw.

In the third case, the symbol ––no matter what it says––gets replaced
by `"([^\\/]+)"`, and again we are in presence of case 1.

The fourth case, again, reverts to the basic matcher: it generates the string
`"([^\\/]+?)\.#{ext}\\z"` before performing the match.

The fifth case is different: it checks if the the parameter supplied is present
in the request (via POST or QUERY_STRING) and it pushes the value as a capture.

Composition
-----------

You can mount a Cuba app, along with middlewares, inside another Cuba app:

``` ruby
class API < Cuba; end

API.use SomeMiddleware

API.define do
  on param("url") do |url|
    ...
  end
end

Cuba.define do
  on "api" do
    run API
  end
end
```

Testing
-------

Given that Cuba is essentially Rack, it is very easy to test with `Webrat` or
`Capybara`. Cuba's own tests are written with a combination of [Cutest][cutest]
and [Capybara][capybara], and if you want to use the same for your tests it is
as easy as requiring `cuba/test`:

``` ruby
require "cuba/test"
require "your/app"

scope do
  test "Homepage" do
    visit "/"

    assert has_content?("Hello world!")
  end
end
```

To read more about testing, check the documentation for [Cutest][cutest] and
[Capybara][capybara].

Settings
--------

Each Cuba app can store settings in the `Cuba.settings` hash. The settings are
inherited if you happen to subclass `Cuba`

``` ruby
Cuba.settings[:layout] = "guest"

class Users < Cuba; end
class Admin < Cuba; end

Admin.settings[:layout] = "admin"

assert_equal "guest", Users.settings[:layout]
assert_equal "admin", Admin.settings[:layout]
```

Feel free to store whatever you find convenient.

Rendering
---------

Cuba ships with a plugin that provides helpers for rendering templates. It uses
[Tilt][tilt], a gem that interfaces with many template engines.

``` ruby
require "cuba/render"

Cuba.plugin Cuba::Render

Cuba.define do
  on default do

    # Within the partial, you will have access to the local variable `content`,
    # that will hold the value "hello, world".
    res.write render("home.haml", content: "hello, world")
  end
end
```

Note that in order to use this plugin you need to have [Tilt][tilt] installed, along
with the templating engines you want to use.

Plugins
-------

Cuba provides a way to extend its functionality with plugins.

### How to create plugins

Authoring your own plugins is pretty straightforward.

``` ruby
module MyOwnHelper
  def markdown(str)
    BlueCloth.new(str).to_html
  end
end

Cuba.plugin MyOwnHelper
```

That's the simplest kind of plugin you'll write. In fact, that's exactly how
the `markdown` helper is written in `Cuba::TextHelpers`.

A more complicated plugin can make use of `Cuba.settings` to provide default
values. In the following example, note that if the module has a `setup` method it will
be called as soon as it is included:

``` ruby
module Render
  def self.setup(app)
    app.settings[:template_engine] = "erb"
  end

  def partial(template, locals = {})
    render("#{template}.#{settings[:template_engine]}", locals)
  end
end

Cuba.plugin Render
```

This sample plugin actually resembles how `Cuba::Render` works.

Finally, if a module called `ClassMethods` is present, `Cuba` will be extended
with it.

``` ruby
module GetSetter
  module ClassMethods
    def set(key, value)
      settings[key] = value
    end

    def get(key)
      settings[key]
    end
  end
end

Cuba.plugin GetSetter

Cuba.set(:foo, "bar")

assert_equal "bar", Cuba.get(:foo)
assert_equal "bar", Cuba.settings[:foo]
```

Installation
------------

``` ruby
$ gem install cuba
```
