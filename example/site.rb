require "cuba"

Cuba.define do
  on get do
    on path("dashboard") do
      res.write "Welcome to your Dashboard"
    end

    on path("login") do
      @greeting = "Hello World!"
      res.write render("templates/form.erb")
    end

    on default do
      res.redirect "login"
    end
  end

  on post do
    on path("login") do
      on param("user") do |user|
        res.write "Got #{user}"
      end

      on default do
        res.write "You should provide a username"
      end
    end
  end
end
