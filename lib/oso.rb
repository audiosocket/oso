require "timeout"
require "net/http"
require "uri"

# A simple client for the Oso URL shortener.

class Oso
  include Timeout

  # Raised for any error.

  Error = Class.new StandardError

  # Duh.

  VERSION = "1.0.0"

  # :nodoc:

  def self.instance
    @instance ||= new
  end

  # A static helper if you don't want to create new instances of the
  # Oso class. Set the <tt>OSO_URL</tt> environment variable to
  # control the server location. See +initialize+ for more
  # information.

  def self.shorten *args
    instance.shorten(*args)
  end

  # A URI. Where does the Oso server live? If unspecified during
  # initialization it'll default to the contents of the
  # <tt>OSO_URL</tt> environment variable. If that's unset, it's
  # <tt>"http://localhost:9292"</tt>.

  attr_reader :url

  # Create a new instance, optionally specifying the server +url+. See
  # the +url+ property for defaults and fallbacks.

  def initialize url = nil
    url = url || ENV["OSO_URL"] || "http://localhost:9292"
    url = "http://#{url}" unless /^http/ =~ url

    @url = URI.parse url
    @url.path = "/" if @url.path.empty?
  end

  # Create a short URL for +url+. Pass a <tt>:life</tt> option
  # (integer, in seconds) to control how long the short URL will be
  # active.
  #
  # +shorten+ will raise a Timeout::Error if network or server
  # conditions keep +url+ from being shortened in one second.

  def shorten url, options = {}
    params = { url: url }
    params[:life] = options[:life].to_i if options[:life]

    timeout 1, Oso::Error do
      begin
        res = Net::HTTP.post_form @url, params
      rescue Errno::ECONNREFUSED
        raise Oso::Error, "Connection to #@url refused."
      rescue Timeout::Error
        raise Oso::Error, "Connection to #@url timed out."
      rescue Errno::EINVAL, Errno::ECONNRESET, EOFError => e
        raise Oso::Error, "Connection to #@url failed. (#{e.class.name})"
      rescue Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError => e
        raise Oso::Error, "#@url provided a bad response. (#{e.class.name})"
      end

      case res.code.to_i
      when 201 then return res.body
      else raise Oso::Error, "Unsuccessful shorten #{res.code}: #{res.body}"
      end
    end
  end
end
