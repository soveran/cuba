Gem::Specification.new do |s|
  s.name              = "cuba"
  s.version           = "3.4.0"
  s.summary           = "Microframework for web applications."
  s.description       = "Cuba is a microframework for web applications."
  s.authors           = ["Michel Martens"]
  s.email             = ["michel@soveran.com"]
  s.homepage          = "https://github.com/soveran/cuba"
  s.license           = "MIT"

  s.files = `git ls-files`.split("\n")

  s.add_dependency "rack", ">= 1.6.4"

  s.add_development_dependency "cutest", "~> 1.2"
  s.add_development_dependency "rack-test", "~> 0.6"
  s.add_development_dependency "tilt", "~> 2.0"
end
