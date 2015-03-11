class Cuba
  module Safe
    module CSRF
      def csrf
        @csrf ||= Cuba::Safe::CSRF::Helper.new(req)
      end

      class Helper
        attr :req

        def initialize(req)
          @req = req
        end

        def token
          session[:csrf_token] ||= SecureRandom.base64(32)
        end

        def reset!
          session.delete(:csrf_token)
        end

        def safe?
          return req.get? || req.head? ||
            req[:csrf_token] == token ||
            req.env["HTTP_X_CSRF_TOKEN"] == token
        end

        def unsafe?
          return !safe?
        end

        def form_tag
          return %Q(<input type="hidden" name="csrf_token" value="#{ token }">)
        end

        def meta_tag
          return %Q(<meta name="csrf_token" content="#{ token }">)
        end

        def session
          return req.env["rack.session"]
        end
      end
    end
  end
end
