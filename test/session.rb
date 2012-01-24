require_relative "helper"

test do
  Cuba.define do
    on default do
      begin
        session
      rescue Exception => e
        res.write e.message
      end
    end
  end

  _, _, body = Cuba.call({})

  body.each do |e|
    assert e =~ /Cuba.use Rack::Session::Cookie/
  end
end


