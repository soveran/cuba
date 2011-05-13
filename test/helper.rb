$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require "cuba"

prepare { Cuba.reset! }
