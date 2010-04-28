require "cuba/version"
require "cuba/ron"

module Cuba
  def self.define(&block)
    @app = Ron.new(&block)
  end

  def self.call(env)
    @app.call(env)
  end
end
