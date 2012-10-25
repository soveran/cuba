#! /usr/bin/env unicorn

# Run with:
#
#   $ ./examples/chunked.ru
#
# Then point your browser to http://localhost:8080
#
# Or:
#
#   $ curl -iN http://localhost:8080
#

require File.expand_path("../lib/cuba", File.dirname(__FILE__))

run Cuba.new {
  on root do
    io = File.open("/dev/urandom")

    res.chunked do |body|
      body << "Look ma, random stuff!"
      body << "<br>"

      while line = io.gets
        body << [line].pack("m*")
        body << "<br>"
        sleep(1)
      end
    end
  end
}
