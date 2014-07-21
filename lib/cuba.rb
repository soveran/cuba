require "rack"
require "time"

class Cuba
  class Response
    attr_accessor :status

    attr :headers

    def initialize(status = 200,
                   headers = { "Content-Type" => "text/html; charset=utf-8" })

      @status  = status
      @headers = headers
      @body    = []
      @length  = 0
    end

    def [](key)
      @headers[key]
    end

    def []=(key, value)
      @headers[key] = value
    end

    def write(str)
      s = str.to_s

      @length += s.bytesize
      @headers["Content-Length"] = @length.to_s
      @body << s
    end

    def redirect(path, status = 302)
      @headers["Location"] = path
      @status  = status
    end

    def finish
      [@status, @headers, @body]
    end

    def set_cookie(key, value)
      Rack::Utils.set_cookie_header!(@headers, key, value)
    end

    def delete_cookie(key, value = {})
      Rack::Utils.delete_cookie_header!(@headers, key, value)
    end
  end

  module Base
    module ClassMethods
      def reset!
        @app = nil
        @prototype = nil
      end

      def app
        @app ||= Rack::Builder.new
      end

      def use(middleware, *args, &block)
        app.use(middleware, *args, &block)
      end

      def define(&block)
        app.run new(&block)
      end

      def prototype
        @prototype ||= app.to_app
      end

      def call(env)
        prototype.call(env)
      end

      def plugin(mixin)
        include mixin
        extend  mixin::ClassMethods if defined?(mixin::ClassMethods)

        mixin.setup(self) if mixin.respond_to?(:setup)
      end

      def settings
        @settings ||= {}
      end

      def deepclone(obj)
        Marshal.load(Marshal.dump(obj))
      end

      def inherited(child)
        child.settings.replace(deepclone(settings))
      end
    end

    attr :env
    attr :req
    attr :res
    attr :captures

    def initialize(&blk)
      @blk = blk
      @captures = []
    end

    def settings
      self.class.settings
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      @env = env
      @req = settings[:req].new(env)
      @res = settings[:res].new

      # This `catch` statement will either receive a
      # rack response tuple via a `halt`, or will
      # fall back to issuing a 404.
      #
      # When it `catch`es a throw, the return value
      # of this whole `call!` method will be the
      # rack response tuple, which is exactly what we want.
      catch(:halt) do
        instance_eval(&@blk)

        res.status = 404
        res.finish
      end
    end

    def session
      env["rack.session"] || raise(RuntimeError,
        "You're missing a session handler. You can get started " +
        "by adding Cuba.use Rack::Session::Cookie")
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
    #     res.write "Signup"
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

        # The captures we yield here were generated and assembled
        # by evaluating each of the `arg`s above. Most of these
        # are carried out by #consume.
        yield(*captures)

        halt res.finish
      end
    end

    # @private Used internally by #on to ensure that SCRIPT_NAME and
    #          PATH_INFO are reset to their proper values.
    def try
      script, path = env["SCRIPT_NAME"], env["PATH_INFO"]

      yield

    ensure
      env["SCRIPT_NAME"], env["PATH_INFO"] = script, path
    end
    private :try

    def consume(pattern)
      matchdata = env["PATH_INFO"].match(/\A\/(#{pattern})(\/|\z)/)

      return false unless matchdata

      path, *vars = matchdata.captures

      env["SCRIPT_NAME"] += "/#{path}"
      env["PATH_INFO"] = "#{vars.pop}#{matchdata.post_match}"

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
        accept = String(env["HTTP_ACCEPT"]).split(",")

        if accept.any? { |s| s.strip == mimetype }
          res["Content-Type"] = mimetype
        end
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

    # Access the root of the application.
    #
    # @example
    #
    #   # GET /
    #   on root do
    #     res.write "Home"
    #   end
    def root
      env["PATH_INFO"] == "/" || env["PATH_INFO"] == ""
    end

    # Syntatic sugar for providing HTTP Verb matching.
    #
    # @example
    #   on get, "signup" do
    #   end
    #
    #   on post, "signup" do
    #   end
    def get;    req.get?    end
    def post;   req.post?   end
    def put;    req.put?    end
    def delete; req.delete? end

    # If you want to halt the processing of an existing handler
    # and continue it via a different handler.
    #
    # @example
    #   def redirect(*args)
    #     run Cuba.new { on(default) { res.redirect(*args) }}
    #   end
    #
    #   on "account" do
    #     redirect "/login" unless session["uid"]
    #
    #     res.write "Super secure account info."
    #   end
    def run(app)
      halt app.call(req.env)
    end

    def halt(response)
      throw :halt, response
    end
  end

  extend Base::ClassMethods
  plugin Base
end

Cuba.settings[:req] = Rack::Request
Cuba.settings[:res] = Cuba::Response
