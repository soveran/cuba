Cuba
====

_n_. a microframework for web development.

![Cuba and Rum, by Jan Sochor](http://farm3.static.flickr.com/2619/4032103097_8324c6fecf.jpg)

Community
---------

Meet us on IRC: [#cuba.rb][irc] on [freenode.net][freenode].

[irc]: irc://chat.freenode.net/#cuba.rb
[freenode]: http://freenode.net/

Description
-----------

Cuba is a microframework for web development originally inspired
by [Rum][rum], a tiny but powerful mapper for [Rack][rack]
applications.

It integrates many templates via [Tilt][tilt], and testing via
[Cutest][cutest] and [Capybara][capybara].

[rum]: http://github.com/chneukirchen/rum
[rack]: http://github.com/rack/rack
[tilt]: http://github.com/rtomayko/tilt
[cutest]: http://github.com/djanowski/cutest
[capybara]: http://github.com/jnicklas/capybara
[rack-test]: https://github.com/brynary/rack-test

Installation
------------

``` console
$ gem install cuba
```

Usage
-----

Here's a simple application:

``` ruby
# cat hello_world.rb
require "cuba"
require "cuba/safe"

Cuba.use Rack::Session::Cookie, :secret => "__a_very_long_string__"

Cuba.plugin Cuba::Safe

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
```

And the test file:

``` ruby
# cat hello_world_test.rb
require "cuba/test"
require "./hello_world"

scope do
  test "Homepage" do
    get "/"

    follow_redirect!

    assert_equal "Hello world!", last_response.body
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
require "cuba/safe"

Cuba.use Rack::Session::Cookie, :secret => "__a_very_long_string__"

Cuba.plugin Cuba::Safe

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

      # If the params `user` and `pass` are not provided, this
      # block will get executed.
      on true do
        res.write "You need to provide user and pass!"
      end
    end
  end
end
```

Note that once an `on` block matches, processing halts at the conclusion of that block.

Status codes
------------

If you don't assign a status code and you don't write to the `res`
object, the status will be set as `404`. The method `not_found` is
in charge of setting the proper status code, and you can redefine
it if you want to render a template or configure custom headers.

For example:

``` ruby
Cuba.define do
  on get do
    on "hello" do
      res.write "hello world"
    end
  end
end

# Requests:
#
# GET /            # 404
# GET /hello       # 200
# GET /hello/world # 200
```

As you can see, as soon as something was written to the response,
the status code was changed to 200.

If you want to match just "hello", but not "hello/world", you can do
as follows:

``` ruby
Cuba.define do
  on get do
    on "hello" do
      on root do
        res.write "hello world"
      end
    end
  end
end

# Requests:
#
# GET /            # 404
# GET /hello       # 200
# GET /hello/world # 404
```

You can also use a regular expression to match the end of line:

``` ruby
Cuba.define do
  on get do
    on /hello\/?\z/ do
      res.write "hello world"
    end
  end
end

# Requests:
#
# GET /            # 404
# GET /hello       # 200
# GET /hello/world # 404
```

This last example is not a common usage pattern. It's here only to
illustrate how Cuba can be adapted for different use cases.

If you need this behavior, you can create a helper:

``` ruby
module TerminalMatcher
  def terminal(path)
    /#{path}\/?\z/
  end
end

Cuba.plugin TerminalMatcher

Cuba.define do
  on get do
    on terminal("hello") do
      res.write "hello world"
    end
  end
end
```

Security
--------

The most important security consideration is to use `https` for all
requests. If that's not the case, any attempt to secure the application
could be in vain. The rest of this section assumes `https` is
enforced.

When building a web application, you need to include a security
layer. Cuba ships with the `Cuba::Safe` plugin, which applies several
security related headers to prevent attacks like clickjacking and
cross-site scripting, among others. It is not included by default
because there are legitimate uses for plain Cuba (for instance,
when designing an API).

Here's how to include it:

```ruby
require "cuba/safe"

Cuba.plugin Cuba::Safe
```

You should also always set a session secret to some undisclosed
value. Keep in mind that the content in the session cookie is
*not* encrypted.

``` ruby
Cuba.use(Rack::Session::Cookie, :secret => "__a_very_long_string__")
```

In the end, your application should look like this:

```ruby
require "cuba"
require "cuba/safe"

Cuba.use Rack::Session::Cookie, :secret => "__a_very_long_string__"

Cuba.plugin Cuba::Safe

Cuba.define do
  on csrf.unsafe? do
    csrf.reset!

    res.status = 403
    res.write("Not authorized")

    halt(res.finish)
  end

  # Now your app is protected against a wide range of attacks.
  ...
end
```

The `Cuba::Safe` plugin is composed of two modules:

* `Cuba::Safe::SecureHeaders`
* `Cuba::Safe::CSRF`

You can include them individually, but while the modularity is good
for development, it's very common to use them in tandem. As that's
the normal use case, including `Cuba::Safe` is the preferred way.

Cross-Site Request Forgery
--------------------------

The `Cuba::Safe::CSRF` plugin provides a `csrf` object with the
following methods:

* `token`: the current security token.
* `reset!`: forces the token to be recreated.
* `safe?`: returns `true` if the request is safe.
* `unsafe?`: returns `true` if the request is unsafe.
* `form_tag`: returns a string with the `csrf_token` hidden input tag.
* `meta_tag`: returns a string with the `csrf_token` meta tag.

Here's an example of how to use it:

```ruby
require "cuba"
require "cuba/safe"

Cuba.use Rack::Session::Cookie, :secret => "__a_very_long_string__"

Cuba.plugin Cuba::Safe

Cuba.define do
  on csrf.unsafe? do
    csrf.reset!

    res.status = 403
    res.write("Forbidden")

    halt(res.finish)
  end

  # Here comes the rest of your application
  # ...
end
```

You have to include `csrf.form_tag` in your forms and `csrf.meta_tag`
among your meta tags. Here's an example that assumes you are using
`Cuba::Mote` from `cuba-contrib`:

```html
<!DOCTYPE html>
<html>
  <head>
    {{ app.csrf.meta_tag }}
    ...
  </head>
  ...
  <body>
    <form action="/foo" method="POST">
      {{ app.csrf.form_tag }}
      ...
    </form>
  ...
  </body>
</html>
```

HTTP Verbs
----------

There are matchers defined for the following HTTP Verbs: `get`,
`post`, `put`, `patch`, `delete`, `head`, `options`, `link`, `unlink`
and `trace`. As you have the whole request available via the `req`
object, you can also query it with helper methods like `req.options?`
or `req.head?`, or you can even go to a lower level and inspect the
environment via the `env` object, and check for example if
`env["REQUEST_METHOD"]` equals the verb `PATCH`.

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

[request]: http://www.rubydoc.info/github/rack/rack/Rack/Request
[response]: http://www.rubydoc.info/github/rack/rack/Rack/Response

Those objects are helpers for accessing the request and for building
the response. Most of the time, you will just use `res.write`.

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

In the third case, the symbol--no matter what it says--gets replaced
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

If you need to pass information to one sub-app, you can use the
`with` method and access it with `vars`:

```ruby
class Platforms < Cuba
  define do
    platform = vars[:platform]

    on default do
      res.write(platform) # => "heroku" or "salesforce"
    end
  end
end

Cuba.define do
  on "(heroku|salesforce)" do |platform|
    with(platform: platform) do
      run(Platforms)
    end
  end
end
```

## Embedding routes from other modules

While the `run` command allows you to handle over the control to a
sub app, sometimes you may want to just embed routes defined in
another module. There's no built-in method to do it, but if you are
willing to experiment you can try the following.

Let's say you have defined routes in modules `A` and `B`, and you
want to mount those routes in your application.

First, you will have to extend Cuba with this code:

```ruby
class Cuba
  def mount(app)
    result = app.call(req.env)
    halt result if result[0] != 404
  end
end
```

It doesn't matter where you define it as long as Cuba has already
been required. For instance, you could extract that to a plugin and
it would work just fine.

Then, in your application, you can use it like this:

```ruby
Cuba.define do
  on default do
    mount A 
    mount B
  end
end
```

It should halt the request only if the resulting status from calling
the mounted app is not 404. If you run into some unexpected behavior,
let me know by creating an issue and we'll look at how to workaround
any difficulties.

Testing
-------

Given that Cuba is essentially Rack, it is very easy to test with
`Rack::Test`, `Webrat` or `Capybara`. Cuba's own tests are written
with a combination of [Cutest][cutest] and [Rack::Test][rack-test],
and if you want to use the same for your tests it is as easy as
requiring `cuba/test`:

``` ruby
require "cuba/test"
require "your/app"

scope do
  test "Homepage" do
    get "/"

    assert_equal "Hello world!", last_response.body
  end
end
```

If you prefer to use [Capybara][capybara], instead of requiring
`cuba/test` you can require `cuba/capybara`:

``` ruby
require "cuba/capybara"
require "your/app"

scope do
  test "Homepage" do
    visit "/"

    assert has_content?("Hello world!")
  end
end
```

To read more about testing, check the documentation for
[Cutest][cutest], [Rack::Test][rack-test] and [Capybara][capybara].

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

Cuba includes a plugin called `Cuba::Render` that provides a couple of helper
methods for rendering templates. This plugin uses [Tilt][tilt], which serves as
an interface to a bunch of different Ruby template engines (ERB, Haml, Sass,
CoffeeScript, etc.), so you can use the template engine of your choice.

To set up `Cuba::Render`, do:

```ruby
require "cuba"
require "cuba/render"
require "erb"

Cuba.plugin Cuba::Render
```

This example uses ERB, a template engine that comes with Ruby. If you want to
use another template engine, one [supported by Tilt][templates], you need to
install the required gem and change the `template_engine` setting as shown
below.

```ruby
Cuba.settings[:render][:template_engine] = "haml"
```

The plugin provides three helper methods for rendering templates: `partial`,
`view` and `render`.

```ruby
Cuba.define do
  on "about" do
    # `partial` renders a template called `about.erb` without a layout.
    res.write partial("about")
  end

  on "home" do
    # Opposed to `partial`, `view` renders the same template
    # within a layout called `layout.erb`.
    res.write view("about")
  end

  on "contact" do
    # `render` is a shortcut to `res.write view(...)`
    render("contact")
  end
end
```

By default, `Cuba::Render` assumes that all templates are placed in a folder
named `views` and that they use the proper extension for the chosen template
engine. Also for the `view` and `render` methods, it assumes that the layout
template is called `layout`.

The defaults can be changed through the `Cuba.settings` method:

```ruby
Cuba.settings[:render][:template_engine] = "haml"
Cuba.settings[:render][:views] = "./views/admin/"
Cuba.settings[:render][:layout] = "admin"
```

NOTE: Cuba doesn't ship with Tilt. You need to install it (`gem install tilt`).

[templates]: https://github.com/rtomayko/tilt/blob/master/docs/TEMPLATES.md

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
values. In the following example, note that if the module has a `setup` method, it will
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

Contributing
------------

A good first step is to meet us on IRC and discuss ideas. If that's
not possible, you can create an issue explaning the proposed change
and a use case. We pay a lot of attention to use cases, because our
goal is to keep the code base simple. In many cases, the result of
a conversation will be the creation of another tool, instead of the
modification of Cuba itself.

If you want to test Cuba, you may want to use a gemset to isolate
the requirements. We recommend the use of tools like [dep][dep] and
[gs][gs], but you can use similar tools like [gst][gst] or [bs][bs].

The required gems for testing and development are listed in the
`.gems` file. If you are using [dep][dep], you can create a gemset
and run `dep install`.

[dep]: http://cyx.github.io/dep/
[gs]: http://soveran.github.io/gs/
[gst]: https://github.com/tonchis/gst
[bs]: https://github.com/educabilia/bs
