class Cuba
  module Settings
    def settings
      self.class
    end

    module ClassMethods
      def set(key, value)
        metaclass.send :attr_writer, key
        metaclass.module_eval %{
          def #{key}
            @#{key} ||= #{value.inspect}
          end
        }

        send :"#{key}=", value
      end

    private
      def metaclass
        class << self; self; end
      end
    end
  end
end