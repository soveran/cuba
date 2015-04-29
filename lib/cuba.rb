require "rack"
require "syro"

class Cuba < Syro::Deck
  def self.define(&code)
    app.run(Syro.new(self, &code))
  end

  def self.call(env)
    return prototype.call(env)
  end

  def self.prototype
    @prototype ||= app.to_app
  end

  def self.app
    @app ||= Rack::Builder.new
  end

  def self.reset!
    @app = @prototype = nil
  end

  def self.use(middleware, *args, &block)
    app.use(middleware, *args, &block)
  end

  def self.plugin(mixin)
    include mixin
    extend mixin::ClassMethods if defined?(mixin::ClassMethods)

    mixin.setup(self) if mixin.respond_to?(:setup)
  end

  def self.settings
    @settings ||= {}
  end

  def self.inherited(child)
    child.settings.replace(deepclone(settings))
  end

  def self.deepclone(obj)
    return Marshal.load(Marshal.dump(obj))
  end

  def settings
    return self.class.settings
  end

  RACK_SESSION = "rack.session"

  def session
    env[RACK_SESSION] || raise(RuntimeError,
      "You're missing a session handler. You can get started " +
      "by adding Cuba.use Rack::Session::Cookie")
  end

  def default
    return true
  end
end
