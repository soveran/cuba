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

    # cat hello_world.rb
    require "cuba"

    Cuba.use Rack::Session::Cookie

    Cuba.define do
      on get do
        on "hello" do
          res.write "Hello world!"
        end

        on true do
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

To run it, you can create a `config.ru` file:

    # cat config.ru
    require "hello_world"

    run Cuba

You can now run `rackup` and enjoy what you have just created.

Matchers
--------

Here's an example showcasing how different matchers work:

    require "cuba"

    Cuba.use Rack::Session::Cookie

    Cuba.define do

      # only GET requests
      on get do

        # /
        on "" do
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
        on "login"

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

HTTP Verbs
----------

There are four matchers defined for HTTP Verbs: `get`, `post`, `put` and
`delete`. But the world doesn't end there, does it? As you have the whole
request available via the `req` object, you can query it with helper methods
like `req.options?` or `req.head?`, or you can even go to a lower level
and inspect the environment via the `env` object, and check for example if
`env["REQUEST_METHOD"]` equals the obscure verb `PATCH`.

What follows is an example of different ways of saying the same thing:

    on env["REQUEST_METHOD"] == "GET", "api" do ... end

    on req.get?, "api" do ... end

    on get, "api" do ... end

Actually, `get` is syntax sugar for `req.get?`, which in turn is syntax sugar
for `env["REQUEST_METHOD"] == "GET"`.

Captures
--------

You may have noticed that some matchers yield a value to the block. The rules
for determining if a matcher will yield a value are simple:

1. Regex captures: `"posts/(\d+)-(.*)"` will yield two values, corresponding to each capture.
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

    API = Cuba.build

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

Testing
-------

Given that Cuba is essentially Rack, it is very easy to test with `Webrat` or
`Capybara`. Cuba's own tests are written with a combination of [Cutest][cutest]
and [Capybara][capybara], and if you want to use the same for your tests it is
as easy as requiring `cuba/test`:

    require "cuba/test"
    require "your/app"

    scope do
      test "Homepage" do
        visit "/"

        assert has_content?("Hello world!")
      end
    end

To read more about testing, check the documentation for [Cutest][cutest] and
[Capybara][capybara].

Installation
------------

    $ gem install cuba
