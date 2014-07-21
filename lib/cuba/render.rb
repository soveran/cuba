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

    def view(template, locals = {}, layout = settings[:render][:layout])
      partial(layout, { content: partial(template, locals) }.merge(locals))
    end

    def template_path(template)
      "%s/%s.%s" % [
        settings[:render][:views],
        template,
        settings[:render][:template_engine]
      ]
    end

    def partial(template, locals = {})
      render(template_path(template), locals, settings[:render][:options])
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
        if template_block = options[:template_block]
          template_class = Tilt[settings[:render][:template_engine]]
        else
          template_class = Tilt
        end

        template_class.new(template, 1, options.merge(outvar: '@_output'), &template_block)
      }.render(self, locals, &block)
    end

    # @private Used internally by #render to cache the
    #          Tilt templates.
    def _cache
      Thread.current[:_cache] ||= Tilt::Cache.new
    end
    private :_cache
  end
end
