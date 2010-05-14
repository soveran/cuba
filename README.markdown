Cuba
====

Rum based microframework for web development.

![Cuba and Rum, by Jan Sochor](http://farm3.static.flickr.com/2619/4032103097_8324c6fecf.jpg)

Description
-----------

Cuba is a light wrapper around [Rum](http://github.com/chneukirchen/rum), a tiny but powerful mapper for [Rack](http://github.com/chneukirchen/rack) applications.

It integrates [Haml](http://haml-lang.com/) templates via [Tilt](http://github.com/rtomayko/tilt), and testing via [Contest](http://github.com/citrusbyte/contest) and [Stories](http://github.com/citrusbyte/stories).

Usage
-----

Here's a simple application:

    # cat hello_world.rb
    require "cuba"

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

    Cuba.test "My App" do
      story "As a user I want to be greeted with a Hello world" do
        scenario "A user visits the homepage" do
          visit "/"

          assert_contain "Hello world!"
        end
      end
    end

To run it, you can create a `config.ru`:

    # cat config.ru
    require "hello_world"

    run Cuba

That's it, you can now run `rackup` and enjoy what you have just created.

For more information about what you can do, check [Rum's documentation](http://github.com/chneukirchen/rum). To see how you can test it, check the documentation for [Stories](http://github.com/citrusbyte/stories).

Installation
------------

    $ sudo gem install cuba

License
-------

Copyright (c) 2010 Michel Martens

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
