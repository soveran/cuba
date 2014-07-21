require_relative "helper"

scope do
  module Helper
    def clean(str)
      str.strip
    end
  end

  test do
    Cuba.plugin Helper

    Cuba.define do
      on default do
        res.write clean " foo "
      end
    end

    _, _, body = Cuba.call({})

    assert_response body, ["foo"]
  end
end

scope do
  module Number
    def num
      1
    end
  end

  module Plugin
    def self.setup(app)
      app.plugin Number
    end

    def bar
      "baz"
    end

    module ClassMethods
      def foo
        "bar"
      end
    end
  end

  setup do
    Cuba.plugin Plugin

    Cuba.define do
      on default do
        res.write bar
        res.write num
      end
    end
  end

  test do
    assert_equal "bar", Cuba.foo
  end

  test do
    _, _, body = Cuba.call({})

    assert_response body, ["baz", "1"]
  end
end

scope do
  module Helper
    module ClassMethods
      def settings
        super.merge(:foo=>:bar)
      end
    end
    def accept(mimetype)
      if mimetype =~ /(\w+)\/\*/
        type = $1
        String(env["HTTP_ACCEPT"]) =~ /#{type}\/\w+/
      else
        super
      end
    end
  end

  test do
    Cuba.plugin Helper

    Cuba.define do
      on accept('text/*') do
        res.write "foo#{settings[:foo]}"
      end
      on accept('application/xml') do
        res.write "bar"
      end
      on default do
        res.write "baz"
      end
    end

    assert_response Cuba.call("HTTP_ACCEPT"=>'application/xml').last, ['bar']
    assert_response Cuba.call("HTTP_ACCEPT"=>'text/foo').last, ['foobar']
    assert_response Cuba.call({}).last, ['baz']
  end
end

