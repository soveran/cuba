Cuba
====

Rum based microframework for web development.

![Cuba and Rum, by Jan Sochor](http://farm3.static.flickr.com/2619/4032103097_8324c6fecf.jpg)

Description
-----------

Cuba is a microframework for web development heavily inspired by [Rum][rum],
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
        on path("hello") do
          res.write "Hello world!"
        end

        on default do
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

That's it, you can now run `rackup` and enjoy what you have just created.

For more information about what you can do, check [Rum's documentation][rum].
To see how you can test it, check the documentation for [Cutest][cutest] and
[Capybara][capybara].

Installation
------------

    $ gem install cuba