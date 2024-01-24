# == Secure HTTP Headers
#
# This plugin will automatically apply several headers that are
# related to security. This includes:
#
#   - HTTP Strict Transport Security (HSTS) [2].
#   - X-Frame-Options [3].
#   - X-XSS-Protection [4].
#   - X-Content-Type-Options [5].
#   - X-Download-Options [6].
#   - X-Permitted-Cross-Domain-Policies [7].
#
# Due to HTTP/2 specifications and Rack specifications, field names are applied in all lowercase.
#
# == References
#
# [1]: https://github.com/twitter/secureheaders
# [2]: https://tools.ietf.org/html/rfc6797
# [3]: https://tools.ietf.org/html/draft-ietf-websec-x-frame-options-02
# [4]: http://msdn.microsoft.com/en-us/library/dd565647(v=vs.85).aspx
# [5]: http://msdn.microsoft.com/en-us/library/ie/gg622941(v=vs.85).aspx
# [6]: http://msdn.microsoft.com/en-us/library/ie/jj542450(v=vs.85).aspx
# [7]: https://www.adobe.com/devnet/adobe-media-server/articles/cross-domain-xml-for-streaming.html
# [8]: https://datatracker.ietf.org/doc/html/rfc9113#name-http-fields
#
class Cuba
  module Safe
    module SecureHeaders
      HEADERS = {
        "x-content-type-options" => "nosniff",
        "x-download-options" => "noopen",
        "x-frame-options" => "SAMEORIGIN",
        "x-permitted-cross-domain-policies" => "none",
        "x-xss-protection" => "1; mode=block",
        "strict-transport-security" => "max-age=2628000"
      }

      def self.setup(app)
        app.settings[:default_headers].merge!(HEADERS)
      end
    end
  end
end
