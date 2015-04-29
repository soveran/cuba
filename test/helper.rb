require_relative "../lib/cuba"
require "rack/test"

prepare do
  Cuba.reset!
end

class Driver
  include Rack::Test::Methods

  attr :app

  def initialize(app)
    @app = app
  end

  def res
    last_response
  end
end
