require "webrat"
require "rack/test"
require "stories"
require "stories/runner"

Webrat.configure do |config|
  config.mode = :rack
end

class Test::Unit::TestCase
  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers
  include Stories::Webrat

  def app
    Cuba.app
  end
end

module Cuba
  def self.test(name, &block)
    Test::Unit::TestCase.context(name, &block)
  end
end
