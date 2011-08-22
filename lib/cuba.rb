require "cuba/version"
require "cuba/ron"

class Cuba
  def self.reset!
    @app = nil
    @prototype = nil
  end

  def self.app
    @app ||= Rack::Builder.new
  end

  def self.use(middleware, *args, &block)
    app.use(middleware, *args, &block)
  end

  def self.define(&block)
    app.run Cuba::Ron.new(&block)
  end

  def self.new
    Class.new(self)
  end

  def self.prototype
    @prototype ||= app.to_app
  end

  def self.call(env)
    prototype.call(env)
  end
end