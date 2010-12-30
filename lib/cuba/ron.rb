require "cuba/rum"
require "tilt"

module Cuba
  class Ron < Rum
    def _cache
      Thread.current[:_cache] ||= Tilt::Cache.new
    end

    def render(template, locals = {}, options = {})
      _cache.fetch(template, locals) {
        Tilt.new(template, 1, options)
      }.render(self, locals)
    end

    def session
      @session ||= env['rack.session']
    end
  end
end
