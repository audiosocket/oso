require "timeout"
require "net/http"
require "uri"

# A simple client for the Oso URL shortener.

class Oso
  include Timeout

  # Raised for any error.

  Error = Class.new StandardError

  # Duh.

  VERSION = "2.0.1"

  # :nodoc:

  def self.instance
    @instance ||= new
  end

  # :nodoc:

  def self.reset!
    @instance = nil
  end

  # A static helper if you don't want to create new instances of the
  # Oso class. Set the <tt>OSO_URL</tt> environment variable to
  # control the server location. See +initialize+ for more
  # information.

  def self.shorten *args
    instance.shorten(*args)
  end

  # See #shorten! for more information.

  def self.shorten! *args
    instance.shorten!(*args)
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
  # active. Pass a <tt>:limit</tt> option to control how many times
  # the URL can be hit before it's deactivated. Pass a <tt>:name</tt>
  # option to explicitly set the shortened URL.
  #
  # +shorten!+ will raise an Oso::Error if network or server
  # conditions keep +url+ from being shortened in one second.
  
  def shorten! url, options = {}
    params = options.merge :url => url

    params[:life]  &&= params[:life].to_i
    params[:limit] &&= params[:limit].to_i

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

  # Create a short URL like #shorten!, but return the original URL if
  # an error is raised.

  def shorten url, options = {}
    shorten! url, options rescue url
  end
end
