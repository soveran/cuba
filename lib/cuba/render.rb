require "tilt"

class Cuba
  module Render
    def self.setup(app)
      app.settings[:render] ||= {}
      app.settings[:render][:template_engine] ||= "erb"
      app.settings[:render][:layout] ||= "layout"
      app.settings[:render][:views] ||= File.expand_path("views", Dir.pwd)
      app.settings[:render][:options] ||= {
        default_encoding: Encoding.default_external
      }
    end

    def render(template, locals = {}, layout = settings[:render][:layout])
      res.headers["content-type"] ||= "text/html; charset=utf-8"
      res.write(view(template, locals, layout))
    end

    def view(template, locals = {}, layout = settings[:render][:layout])
      partial(layout, locals.merge(content: partial(template, locals)))
    end

    def partial(template, locals = {})
      _render(template_path(template), locals, settings[:render][:options])
    end

    def template_path(template)
      dir = settings[:render][:views]
      ext = settings[:render][:template_engine]

      return File.join(dir, "#{ template }.#{ ext }")
    end

    # @private Renders any type of template file supported by Tilt.
    #
    # @example
    #
    #   # Renders home, and is assumed to be HAML.
    #   _render("home.haml")
    #
    #   # Renders with some local variables
    #   _render("home.haml", site_name: "My Site")
    #
    #   # Renders with HAML options
    #   _render("home.haml", {}, ugly: true, format: :html5)
    #
    #   # Renders in layout
    #   _render("layout.haml") { _render("home.haml") }
    #
    def _render(template, locals = {}, options = {}, &block)
      _cache.fetch(template) {
        Tilt.new(template, 1, options.merge(outvar: '@_output'))
      }.render(self, locals, &block)
    end

    # @private Used internally by #_render to cache the
    #          Tilt templates.
    def _cache
      Thread.current[:_cache] ||= Tilt::Cache.new
    end
  end
end
