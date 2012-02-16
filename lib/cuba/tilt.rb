require "tilt"

class Cuba
  module Tilt
    def self.setup(app)
      app.settings[:template_engine] ||= "erb"
      app.settings[:views] ||= File.expand_path("views", Dir.pwd)
    end

    def view(template, locals = {}, layout = "layout")
      partial(layout, { content: partial(template, locals) }.merge(locals))
    end

    def partial(template, locals = {})
      render("#{settings[:views]}/#{template}.#{settings[:template_engine]}",
        locals, default_encoding: Encoding.default_external)
    end

    # Render any type of template file supported by Tilt.
    #
    # @example
    #
    #   # Renders home, and is assumed to be HAML.
    #   render("home.haml")
    #
    #   # Renders with some local variables
    #   render("home.haml", site_name: "My Site")
    #
    #   # Renders with HAML options
    #   render("home.haml", {}, ugly: true, format: :html5)
    #
    #   # Renders in layout
    #   render("layout.haml") { render("home.haml") }
    #
    def render(template, locals = {}, options = {}, &block)
      _cache.fetch(template) {
        ::Tilt.new(template, 1, options)
      }.render(self, locals, &block)
    end

    # @private Used internally by #render to cache the
    #          Tilt templates.
    def _cache
      Thread.current[:_cache] ||= ::Tilt::Cache.new
    end
    private :_cache
  end
end
