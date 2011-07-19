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

      catch(:ron_run_next_app) do
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
    #   # Renders in layout
    #   render("layout.haml") { render("home.haml") }
    #
    def render(template, locals = {}, options = {}, &block)
      _cache.fetch(template, locals) {
        Tilt.new(template, 1, options)
      }.render(self, locals, &block)
    end

    # The heart of the path / verb / any condition matching.
    #
    # @example
    #
    #   on get do
    #     res.write "GET"
    #   end
    #
    #   on get, "signup" do
    #     res.write "Signup
    #   end
    #
    #   on "user/:id" do |uid|
    #     res.write "User: #{uid}"
    #   end
    #
    #   on "styles", extension("css") do |file|
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
        #    on true, "signup"
        return unless args.all? { |arg| match(arg) }

        begin
          # The captures we yield here were generated and assembled
          # by evaluating each of the `arg`s above. Most of these
          # are carried out by #consume.
          yield *captures

        ensure
          # Regardless of what happens in the `yield`, we should ensure that
          # we successfully set `@matched` to true.

          # At this point, we've successfully matched with some corresponding
          # matcher, so we can skip all other matchers defined.
          @matched = true
        end
      end
    end

    # @private Used internally by #on to ensure that SCRIPT_NAME and
    #          PATH_INFO are reset to their proper values.
    def try
      script, path = env["SCRIPT_NAME"], env["PATH_INFO"]

      yield

    ensure
      env["SCRIPT_NAME"], env["PATH_INFO"] = script, path unless @matched
    end
    private :try

    def consume(pattern)
      return unless match = env["PATH_INFO"].match(/\A\/(#{pattern})((?:\/|\z))/)

      path, *vars = match.captures

      env["SCRIPT_NAME"] += "/#{path}"
      env["PATH_INFO"] = "#{vars.pop}#{match.post_match}"

      captures.push(*vars)
    end
    private :consume

    def match(matcher, segment = "([^\\/]+)")
      case matcher
      when String then consume(matcher.gsub(/:\w+/, segment))
      when Regexp then consume(matcher)
      when Symbol then consume(segment)
      when Proc   then matcher.call
      else
        matcher
      end
    end

    # A matcher for files with a certain extension.
    #
    # @example
    #   # PATH_INFO=/style/app.css
    #   on "style", extension("css") do |file|
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
    #   on "signup", param("user") do |atts|
    #     User.create(atts)
    #   end
    def param(key)
      lambda { captures << req[key] unless req[key].to_s.empty? }
    end

    def header(key)
      lambda { env[key.upcase.tr("-","_")] }
    end

    # Useful for matching against the request host (i.e. HTTP_HOST).
    #
    # @example
    #   on host("account1.example.com"), "api" do
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
        String(env["HTTP_ACCEPT"]).split(",").any? { |s| s.strip == mimetype } and
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
    #   on get, "signup" do
    #   end
    #
    #   on post, "signup" do
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
    #   on "account" do
    #     redirect "/login" unless session["uid"]
    #
    #     res.write "Super secure account info."
    #   end
    def run(app)
      throw :ron_run_next_app, app
    end
  end
end