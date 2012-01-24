require "./lib/cuba/version"

Gem::Specification.new do |s|
  s.name              = "cuba"
  s.version           = "2.2.1"
  s.summary           = "Microframework for web applications."
  s.description       = "Cuba is a microframework for web applications."
  s.authors           = ["Michel Martens"]
  s.email             = ["michel@soveran.com"]
  s.homepage          = "http://github.com/soveran/cuba"

  s.files = Dir[
    "LICENSE",
    "README.markdown",
    "Rakefile",
    "lib/**/*.rb",
    "*.gemspec",
    "test/*.*"
  ]

  s.add_dependency "rack"
  s.add_dependency "tilt"
  s.add_development_dependency "cutest"
  s.add_development_dependency "capybara"
end
