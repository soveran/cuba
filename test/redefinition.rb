require File.expand_path("helper", File.dirname(__FILE__))

test "adding your new custom helpers is ok" do
  class Cuba
    def foobar
    end
  end
end

test "redefining standard Cuba methods fails" do
  assert_raise Cuba::RedefinitionError do
    class Cuba
      def get
      end
    end
  end
end