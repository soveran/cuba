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

To run it, you can create a `config.ru`:

    # cat config.ru
    require "hello_world"

    run Cuba

Here's an example showcasing how different matchers work:

    require "cuba"

    Cuba.use Rack::Session::Cookie

    Cuba.define do

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

That's it, you can now run `rackup` and enjoy what you have just created.

To read more about testing, check the documentation for [Cutest][cutest] and
[Capybara][capybara].

Installation
------------

    $ gem install cuba
