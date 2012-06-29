require "cuba"
require "cutest"
require "rack/test"

class Cutest::Scope
  include Rack::Test::Methods

  def app
    Cuba
  end
end
