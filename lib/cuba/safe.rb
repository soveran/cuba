require_relative "safe/csrf"
require_relative "safe/secure_headers"

class Cuba
  # == Cuba::Safe
  #
  # This plugin contains security related features for Cuba
  # applications. It takes ideas from secureheaders[1].
  #
  # == Usage
  #
  #     require "cuba"
  #     require "cuba/safe"
  #
  #     Cuba.plugin(Cuba::Safe)
  #
  module Safe
    def self.setup(app)
      app.plugin(Safe::SecureHeaders)
      app.plugin(Safe::CSRF)
    end
  end
end
