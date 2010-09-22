require "cuba"
require "cutest"
require "capybara/dsl"

class Cutest::Scope
  include Capybara
end

Capybara.app = Cuba
