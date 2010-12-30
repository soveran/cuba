Cuba
====

Rum based microframework for web development.

![Cuba and Rum, by Jan Sochor](http://farm3.static.flickr.com/2619/4032103097_8324c6fecf.jpg)

Description
-----------

Cuba is a light wrapper around [Rum](http://github.com/chneukirchen/rum),
a tiny but powerful mapper for [Rack](http://github.com/chneukirchen/rack)
applications.

It integrates many templates via [Tilt](http://github.com/rtomayko/tilt),
and testing via [Cutest](http://github.com/djanowski/cutest) and
[Capybara](http://github.com/jnicklas/capybara).

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

For more information about what you can do, check [Rum's
documentation](http://github.com/chneukirchen/rum). To see how you can test it,
check the documentation for [Cutest](http://github.com/djanowski/cutest) and
[Capybara](http://github.com/jnicklas/capybara).

Installation
------------

    $ gem install cuba
