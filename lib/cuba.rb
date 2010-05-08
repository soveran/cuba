require "cuba/version"
require "cuba/ron"

module Cuba
  def self.define(&block)
    @app = Rack::Builder.new do
      use Rack::Session::Cookie
      run Cuba::Ron.new(&block)
    end
  end

  def self.call(env)
    @app.call(env)
  end
end
