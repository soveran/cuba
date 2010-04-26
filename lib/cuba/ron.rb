require "cuba/rum"
require "haml"
require "tilt"

module Cuba
  class Ron < Rum
    def _cache
      Thread.current[:_cache] ||= Tilt::Cache.new
    end

    def haml(template, locals = {})
      _cache.fetch(template, locals) {
        Tilt::HamlTemplate.new("#{template}.haml")
      }.render(self, locals)
    end
  end
end
