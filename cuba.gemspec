Gem::Specification.new do |s|
  s.name              = "cuba"
  s.version           = "0.0.2"
  s.summary           = "Rum based microframework for web applications."
  s.description       = "Cuba is a light wrapper for Rum, a microframework for Rack applications."
  s.authors           = ["Michel Martens"]
  s.email             = ["michel@soveran.com"]
  s.homepage          = "http://github.com/soveran/cuba"
  s.files = ["LICENSE", "README.markdown", "Rakefile", "lib/cuba/ron.rb", "lib/cuba/rum.rb", "lib/cuba/test.rb", "lib/cuba/version.rb", "lib/cuba.rb", "cuba.gemspec", "test/cuba_test.rb"]
  s.add_dependency "rack", ">= 1.1.0"
  s.add_dependency "haml", ">= 2.2.22"
  s.add_dependency "tilt", ">= 0.9"
  s.add_dependency "webrat", ">= 0.7.0"
  s.add_dependency "contest", ">= 0.1.2"
  s.add_dependency "stories", ">= 0.1.3"
  s.add_dependency "rack-test", ">= 0.5.3"
end
