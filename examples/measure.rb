require "benchmark"
require "rack"

Benchmark.bmbm do |x|

  x.report "Rack::HeaderHash" do
    1000.times do
      Rack::Utils::HeaderHash.new("Content-Type" => "text/html")
    end
  end

  x.report "Hash" do
    1000.times do
      { "Content-Type" => "text/html" }
    end
  end
end
