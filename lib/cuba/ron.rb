require "rack"
require "tilt"

class Rack::Response
  # 301 Moved Permanently
  # 302 Found
  # 303 See Other
  # 307 Temporary Redirect
  def redirect(target, status = 302)
    self.status = status
    self["Location"] = target
  end
end

# Based on Rum: http://github.com/chneukirchen/rum
#
# Summary of changes
#
# 1. Only relevant captures are yielded.
# 2. The #extension matcher is used more like #path.
# 3. Miscellaneous coding style changes.
#
module Cuba
  class Ron
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

      catch(:rum_run_next_app) do
        instance_eval(&@blk)

        @res.status = 404 unless @matched || !@res.empty?

        return @res.finish
      end.call(env)
    end

    # @private Used internally by #render to cache the
    #          Tilt templates.
    def _cache
      Thread.current[:_cache] ||= Tilt::Cache.new
    end
    private :_cache

    # Render any type of template file supported by Tilt.
    #
    # @example
    #
    #   # Renders home, and is assumed to be HAML.
    #   render("home.haml")
    #
    #   # Renders with some local variables
    #   render("home.haml", site_name: "My Site")
    #
    #   # Renders with HAML options
    #   render("home.haml", {}, ugly: true, format: :html5)
    #
    def render(template, locals = {}, options = {})
      _cache.fetch(template, locals) {
        Tilt.new(template, 1, options)
      }.render(self, locals)
    end

    # Basic wrapper for using Rack session.
    def session
      @session ||= env['rack.session']
    end

    # The heart of the path / verb / any condition matching.
    #
    # @example
    #
    #   on get do
    #     res.write "GET"
    #   end
    #
    #   on get, path("signup") do
    #     res.write "Signup
    #   end
    #
    #   on path("user"), segment do |uid|
    #     res.write "User: #{uid}"
    #   end
    #
    #   on path("styles"), extension("css") do |file|
    #     res.write render("styles/#{file}.sass")
    #   end
    #
    def on(*args, &block)
      # No use running any other matchers if we've already found a
      # proper matcher.
      return if @matched

      try do
        # For every block, we make sure to reset captures so that
        # nesting matchers won't mess with each other's captures.
        @captures = []

        # We stop evaluation of this entire matcher unless
        # each and every `arg` defined for this matcher evaluates
        # to a non-false value.
        #
        # Short circuit examples:
        #    on true, false do
        #
        #    # PATH_INFO=/user
        #    on true, path("signup")
        return unless args.all? { |arg| match(arg) }

        # The captures we yield here were generated and assembled
        # by evaluating each of the `arg`s above. Most of these
        # are carried out by #path.
        yield *captures

        # At this point, we've successfully matched with some corresponding
        # matcher, so we can skip all other matchers defined.
        @matched = true
      end
    end

    # @private Used internally by #on to ensure that SCRIPT_NAME and
    #          PATH_INFO are reset to their proper values.
    def try
      script, path = env["SCRIPT_NAME"], env["PATH_INFO"]

      yield

      env["SCRIPT_NAME"], env["PATH_INFO"] = script, path

    ensure
      unless @matched
        env["SCRIPT_NAME"], env["PATH_INFO"] = script, path
      end
    end
    private :try

    def consume(pattern)
      return unless match = env["PATH_INFO"].match(/\A\/(#{pattern})(?:\/|\z)/)

      path, *vars = match.captures

      env["SCRIPT_NAME"] += "/#{path}"
      env["PATH_INFO"] = "/#{match.post_match}"

      captures.push(*vars)
    end
    private :consume

    def match(matcher)
      case matcher
      when String then consume(matcher.gsub(/:\w+/, "([\\.a-zA-Z0-9\\-]+)"))
      when Regexp then consume(matcher)
      when Symbol then consume("([\\.a-zA-Z0-9\\-]+)")
      when Proc   then matcher.call
      else
        matcher
      end
    end

    # A matcher for files with a certain extension.
    #
    # @example
    #   # PATH_INFO=/style/app.css
    #   on path("style"), extension("css") do |file|
    #     res.write file # writes app
    #   end
    def extension(ext = "\\w+")
      lambda { consume("([^\\/]+?)\.#{ext}\\z") }
    end

    # Used to ensure that certain request parameters are present. Acts like a
    # precondition / assertion for your route.
    #
    # @example
    #   # POST with data like user[fname]=John&user[lname]=Doe
    #   on path("signup"), param("user") do |atts|
    #     User.create(atts)
    #   end
    def param(key, default = nil)
      lambda { captures << (req[key] || default) }
    end

    def header(key, default = nil)
      lambda { env[key.upcase.tr("-","_")] || default }
    end

    # Useful for matching against the request host (i.e. HTTP_HOST).
    #
    # @example
    #   on host("account1.example.com"), path("api") do
    #     res.write "You have reached the API of account1."
    #   end
    def host(hostname)
      hostname === req.host
    end

    # If you want to match against the HTTP_ACCEPT value.
    #
    # @example
    #   # HTTP_ACCEPT=application/xml
    #   on accept("application/xml") do
    #     # automatically set to application/xml.
    #     res.write res["Content-Type"]
    #   end
    def accept(mimetype)
      lambda do
        env["HTTP_ACCEPT"].split(",").any? { |s| s.strip == mimetype } and
          res["Content-Type"] = mimetype
      end
    end

    # Syntactic sugar for providing catch-all matches.
    #
    # @example
    #   on default do
    #     res.write "404"
    #   end
    def default
      true
    end

    # Syntatic sugar for providing HTTP Verb matching.
    #
    # @example
    #   on get, path("signup") do
    #   end
    #
    #   on post, path("signup") do
    #   end
    def get    ; req.get?    end
    def post   ; req.post?   end
    def put    ; req.put?    end
    def delete ; req.delete? end

    # If you want to halt the processing of an existing handler
    # and continue it via a different handler.
    #
    # @example
    #   def redirect(*args)
    #     run Cuba::Ron.new { on(default) { res.redirect(*args) }}
    #   end
    #
    #   on path("account") do
    #     redirect "/login" unless session["uid"]
    #
    #     res.write "Super secure account info."
    #   end
    def run(app)
      throw :rum_run_next_app, app
    end
  end
end