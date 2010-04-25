require "cuba/rum"
require "haml"
require "tilt"

module Cuba
  class Ron < Rum
    def haml(template, locals = {})
      res.write Tilt::HamlTemplate.new("#{template}.haml").render(self, locals)
    end
  end
end
