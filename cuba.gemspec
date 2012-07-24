Gem::Specification.new do |s|
  s.name              = "cuba"
  s.version           = "3.1.0"
  s.summary           = "Microframework for web applications."
  s.description       = "Cuba is a microframework for web applications."
  s.authors           = ["Michel Martens"]
  s.email             = ["michel@soveran.com"]
  s.homepage          = "http://github.com/soveran/cuba"

  s.files = Dir[
    "LICENSE",
    "CHANGELOG",
    "README.md",
    "Rakefile",
    "lib/**/*.rb",
    "*.gemspec",
    "test/*.*"
  ]

  s.add_dependency "rack"
  s.add_development_dependency "cutest"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "tilt"
end
