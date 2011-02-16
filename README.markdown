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

Here's an example showcasing how different matchers work:

    require "cuba"

    Cuba.use Rack::Session::Cookie

    Cuba.define do
      # PATH_INFO=/about
      on path("about") do
        res.write "About"
      end

      # PATH_INFO=/styles/*.css
      on path("styles"), extension("css") do |file|
        res.write "Filename: #{file}"
      end

      # PATH_INFO=/post/YYYY/MM/DD/slug
      on path("post"), number, number, number, segment do |y, m, d, slug|
        res.write "Date: #{y}-#{m}-#{d} Slug: #{slug}"
      end

      # PATH_INFO=/username/*
      on segment do |username|
        user = User.find_by_username(username)

        on path("posts") do
          res.write "Total Posts: #{user.posts.size}"
        end

        on path("following") do
          res.write user.following
        end
      end
    end


That's it, you can now run `rackup` and enjoy what you have just created.

To read more about testing, check the documentation for [Cutest][cutest] and
[Capybara][capybara].

Installation
------------

    $ gem install cuba