require "cuba"

Cuba.use Rack::Session::Cookie

Cuba.define do
  on get do
    on "dashboard" do
      res.write "Welcome to your Dashboard"
    end

    on "login" do
      @greeting = "Hello World!"
      res.write render("templates/form.erb")
    end

    on default do
      res.redirect "login"
    end
  end

  on post do
    on "login" do
      on param("user") do |user|
        res.write "Got #{user}"
      end

      on default do
        res.write "You should provide a username"
      end
    end
  end
end