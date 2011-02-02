$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require "cuba"
require "cutest"

prepare { Cuba.reset! }
