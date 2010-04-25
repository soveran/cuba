require "cuba/version"
require "cuba/ron"

module Cuba
  def self.define(&block)
    @app = Ron.new(&block)
  end

  def self.app
    @app
  end
end
