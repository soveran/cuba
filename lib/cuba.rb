require "cuba/version"
require "cuba/ron"

module Cuba
  def self.app
    @app ||= Rack::Builder.new
  end

  def self.use(middleware)
    app.use(middleware)
  end

  def self.define(&block)
    app.run Cuba::Ron.new(&block)
  end

  def self.call(env)
    app.call(env)
  end
end
