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
# == References
#
# [1]: https://github.com/twitter/secureheaders
# [2]: https://tools.ietf.org/html/rfc6797
# [3]: https://tools.ietf.org/html/draft-ietf-websec-x-frame-options-02
# [4]: http://msdn.microsoft.com/en-us/library/dd565647(v=vs.85).aspx
# [5]: http://msdn.microsoft.com/en-us/library/ie/gg622941(v=vs.85).aspx
# [6]: http://msdn.microsoft.com/en-us/library/ie/jj542450(v=vs.85).aspx
# [7]: https://www.adobe.com/devnet/adobe-media-server/articles/cross-domain-xml-for-streaming.html
#
class Cuba
  module Safe
    module SecureHeaders
      HEADERS = {
        "X-Content-Type-Options" => "nosniff",
        "X-Download-Options" => "noopen",
        "X-Frame-Options" => "SAMEORIGIN",
        "X-Permitted-Cross-Domain-Policies" => "none",
        "X-XSS-Protection" => "1; mode=block",
        "Strict-Transport-Security" => "max-age=2628000"
      }

      def self.setup(app)
        app.settings[:default_headers].merge!(HEADERS)
      end
    end
  end
end
