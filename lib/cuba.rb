require "delegate"
require "rack"
require "rack/session"

class Cuba
  SLASH   = "/".freeze
  EMPTY   = "".freeze
  SEGMENT = "([^\\/]+)".freeze
  DEFAULT = "text/html; charset=utf-8".freeze
  REGEXES = Hash.new { |h, pattern| h[pattern] = /\A\/(#{pattern})(\/|\z)/ }

  class Response
    LOCATION = "location".freeze

    module ContentType
      HTML = "text/html".freeze        # :nodoc:
      TEXT = "text/plain".freeze       # :nodoc:
      JSON = "application/json".freeze # :nodoc:
    end

    attr_accessor :status

    attr :body
    attr :headers

    def initialize(headers = {})
      @status  = nil
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
      @headers[Rack::CONTENT_LENGTH] = @length.to_s
      @body << s
    end

    # Write response body as text/plain
    def text(str)
      @headers[Rack::CONTENT_TYPE] = ContentType::TEXT
      write(str)
    end

    # Write response body as text/html
    def html(str)
      @headers[Rack::CONTENT_TYPE] = ContentType::HTML
      write(str)
    end

    # Write response body as application/json
    def json(str)
      @headers[Rack::CONTENT_TYPE] = ContentType::JSON
      write(str)
    end

    def redirect(path, status = 302)
      @headers[LOCATION] = path
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

  def self.reset!
    @app = nil
    @prototype = nil
  end

  def self.app
    @app ||= Rack::Builder.new
  end

  def self.use(middleware, *args, **kwargs, &block)
    app.use(middleware, *args, **kwargs, &block)
  end

  def self.define(&block)
    app.run new(&block)
  end

  def self.prototype
    @prototype ||= app.to_app
  end

  def self.call(env)
    prototype.call(env)
  end

  def self.plugin(mixin)
    include mixin
    extend  mixin::ClassMethods if defined?(mixin::ClassMethods)

    mixin.setup(self) if mixin.respond_to?(:setup)
  end

  def self.settings
    @settings ||= {}
  end

  def self.deepclone(obj)
    # Hashes with a default_proc cannot be serialized by Marshal.dump.
    if obj.respond_to?(:default_proc)
      proc = obj.default_proc
      obj.default_proc = nil
    end

    new_obj = Marshal.load(Marshal.dump(obj))

    if obj.respond_to?(:default_proc)
      obj.default_proc = proc
    end

    new_obj
  end

  def self.inherited(child)
    child.settings.replace(deepclone(settings))
    child.settings.default_proc = proc do |hash,key|
      hash[key] = self.settings[key]
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
    @res = settings[:res].new(settings[:default_headers].dup)

    # This `catch` statement will either receive a
    # rack response tuple via a `halt`, or will
    # fall back to issuing a 404.
    #
    # When it `catch`es a throw, the return value
    # of this whole `call!` method will be the
    # rack response tuple, which is exactly what we want.
    catch(:halt) do
      instance_eval(&@blk)

      not_found
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

      if res.status.nil?
        if res.body.empty?
          not_found
        else
          res.headers[Rack::CONTENT_TYPE] ||= DEFAULT
          res.status = 200
        end
      end

      halt(res.finish)
    end
  end

  # @private Used internally by #on to ensure that SCRIPT_NAME and
  #          PATH_INFO are reset to their proper values.
  def try
    script, path = env[Rack::SCRIPT_NAME], env[Rack::PATH_INFO]

    yield

  ensure
    env[Rack::SCRIPT_NAME], env[Rack::PATH_INFO] = script, path
  end
  private :try

  def consume(pattern)
    matchdata = env[Rack::PATH_INFO].match(REGEXES[pattern])

    return false unless matchdata

    path, *vars = matchdata.captures

    env[Rack::SCRIPT_NAME] += "/#{path}"
    env[Rack::PATH_INFO] = "#{vars.pop}#{matchdata.post_match}"

    captures.push(*vars)
  end
  private :consume

  def match(matcher, segment = SEGMENT)
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

  # Ensures that certain request parameters are present. Acts like a
  # precondition / assertion for your route. A default value can be
  # provided as a second argument. In that case, it always matches
  # and the result is either the parameter or the default value.
  #
  # @example
  #   # POST with data like user[fname]=John&user[lname]=Doe
  #   on "signup", param("user") do |atts|
  #     User.create(atts)
  #   end
  #
  #   on "login", param("username", "guest") do |username|
  #     # If not provided, username == "guest"
  #   end
  def param(key, default = nil)
    value = req.params[key.to_s] || default

    lambda { captures << value unless value.to_s.empty? }
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
        res[Rack::CONTENT_TYPE] = mimetype
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
    env[Rack::PATH_INFO] == SLASH || env[Rack::PATH_INFO] == EMPTY
  end

  # Syntatic sugar for providing HTTP Verb matching.
  #
  # @example
  #   on get, "signup" do
  #   end
  #
  #   on post, "signup" do
  #   end
  def get;     req.get?     end
  def post;    req.post?    end
  def put;     req.put?     end
  def patch;   req.patch?   end
  def delete;  req.delete?  end
  def head;    req.head?    end
  def options; req.options? end
  def link;    req.link?    end
  def unlink;  req.unlink?  end
  def trace;   req.trace?   end

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

  # Adds ability to pass information to a nested Cuba application.
  # It receives two parameters: a hash that represents the passed
  # information and a block. The #vars method is used to retrieve
  # a hash with the passed information.
  #
  #   class Platforms < Cuba
  #     define do
  #       platform = vars[:platform]
  #
  #       on default do
  #         res.write(platform) # => "heroku" or "salesforce"
  #       end
  #     end
  #   end
  #
  #   Cuba.define do
  #     on "(heroku|salesforce)" do |platform|
  #       with(platform: platform) do
  #         run(Platforms)
  #       end
  #     end
  #   end
  #
  def with(dict = {})
    old, env["cuba.vars"] = vars, vars.merge(dict)
    yield
  ensure
    env["cuba.vars"] = old
  end

  # Returns a hash with the information set by the #with method.
  #
  #   with(role: "admin", site: "main") do
  #     on default do
  #       res.write(vars.inspect)
  #     end
  #   end
  #   # => '{:role=>"admin", :site=>"main"}'
  #
  def vars
    env["cuba.vars"] ||= {}
  end

  def not_found
    res.status = 404
  end
end

Cuba.settings[:req] = Rack::Request
Cuba.settings[:res] = Cuba::Response
Cuba.settings[:default_headers] = {}
