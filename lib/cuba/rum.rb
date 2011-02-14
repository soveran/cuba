# Rum, the gRand Unified Mapper
#
# Rum is a powerful mapper for your Rack applications that can be used
# as a microframework.
#
# More information at http://github.com/chneukirchen/rum
#
# == Copyright
#
# Copyright (C) 2008, 2009 Christian Neukirchen <http://purl.org/net/chneukirchen>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require "rack"

class Rack::Response
  # 301 Moved Permanently
  # 302 Found
  # 303 See Other
  # 307 Temporary Redirect
  def redirect(target, status=302)
    self.status = status
    self["Location"] = target
  end
end

class Rum
  attr :env
  attr :req
  attr :res
  attr :captures

  def initialize(&blk)
    @blk = blk
    @captures = []
  end

  def call(env)
    dup._call(env)
  end

  def _call(env)
    @env = env
    @req = Rack::Request.new(env)
    @res = Rack::Response.new
    @matched = false
    catch(:rum_run_next_app) {
      instance_eval(&@blk)
      @res.status = 404 unless @matched || !@res.empty?
      return @res.finish
    }.call(env)
  end

  def on(*args, &block)
    return if @matched

    s, p = env["SCRIPT_NAME"], env["PATH_INFO"]

    args.each { |a| a == true || (a != false && a.call) || return }

    yield *captures

    env["SCRIPT_NAME"], env["PATH_INFO"] = s, p
    @matched = true
  ensure
    unless @matched
      env["SCRIPT_NAME"], env["PATH_INFO"] = s, p
    end
  end

  def path(p)
    lambda { consume(p) }
  end

  def consume(p)
    return unless match = env["PATH_INFO"].match(/\A\/(#{p})(?:\/|\z)/)

    a, *b = match.captures

    env["SCRIPT_NAME"] += "/#{a}"
    env["PATH_INFO"] = "/#{match.post_match}"

    captures.push(*b)
  end

  def number
    path("(\\d+)")
  end

  def segment
    path("([^\\/]+)")
  end

  def extension(ext = "\\w+")
    path("([^\\/]+?)\.#{ext}\\z")
  end

  def param(key, default = nil)
    lambda { captures << (req[key] || default) }
  end

  def header(key, default = nil)
    lambda { env[key.upcase.tr("-","_")] || default }
  end

  def default
    true
  end

  def host(h)
    req.host == h
  end

  def get    ; req.get?    end
  def post   ; req.post?   end
  def put    ; req.put?    end
  def delete ; req.delete? end

  def accept(mimetype)
    lambda {
      env["HTTP_ACCEPT"].split(",").any? { |s| s.strip == mimetype } and
        res["Content-Type"] = mimetype
    }
  end

  def check(&block)
    block
  end

  def run(app)
    throw :rum_run_next_app, app
  end
end