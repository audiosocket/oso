require "redis/namespace"
require "new_base_60"
require "sinatra"
require "uri"

url = ENV.values_at("OSO_REDIS_URL", "REDISTOGO_URL").compact.first
url = URI.parse url || "redis://localhost:6379"

$redis = Redis::Namespace.new(:oso,
                              :redis => Redis.new(:host => url.host,
                                                  :password => url.password,
                                                  :port => url.port))

configure do
  set :views, Dir.pwd + "/lib/oso/views"
end

helpers do
  def bad! message
    halt 412, {}, message
  end

  def nope!
    redirect "http://audiosocket.com", 301
    # halt 404, {}, "No luck."
  end

  def save short, url, limit, life, metrics=true
    longkey    = "long:#{url}"
    shortkey   = "short:#{short}"
    metricskey = "metrics:#{short}"
    limitkey   = "#{shortkey}:limit"

    $redis.multi do
      $redis.set limitkey, limit if limit
      $redis.set longkey,  short
      $redis.set shortkey, url
      $redis.set metricskey, metrics
    end

    if life
      $redis.expire limitkey, limit if limit
      $redis.expire longkey,  life
      $redis.expire shortkey, life
    end
  end

  def shorten str
    return str unless str.length > 40
    str[0, 37] + "..."
  end

  def shorturl short
    request.path_info = "/#{short}"
    request.url
  end
end

get "/" do
  IO.read "#{settings.public}/index.html"
end

get "/stats" do
  @count   = $redis.get(:counter).to_i
  @hits    = $redis.get(:hits).to_i
  @misses  = $redis.get(:misses).to_i
  @byhits  = Hash[*$redis.zrevrange("by:hits", 0, 50, :with_scores => true)]
  @bytimes = Hash[*$redis.zrevrange("by:time", 0, 50, :with_scores => true)]

  [@byhits, @bytimes].each do |h|
    h.select! { |k, v| $redis.exists "short:#{k}" }
    h.each  { |k, v| h[k] = { :long => $redis.get("short:#{k}"), :score => v } }
  end

  @title = "Stats"
  erb :stats
end

post "/" do
  bad! "Missing url."   unless url = params[:url]

  url = "http://#{url}" unless /^http/i =~ url

  bad! "Malformed url." unless (u = URI.parse url) && /^http/ =~ u.scheme

  life    = params[:life].to_i if params[:life]
  limit   = params[:limit].to_i if params[:limit]
  short   = params[:name] if params[:name] && /[-a-z0-9]+/i =~ params[:name]
  metrics = params.fetch :metrics, true

  bad! "Name is already taken." if short && $redis.exists("short:#{short}")

  if !short && existing = $redis.get("long:#{url}")
    halt 201, {}, shorturl(existing)
  end

  short ||= $redis.incr(:counter).to_sxg
  save short, url, limit, life, metrics

  [201, {}, shorturl(short)]
end

get "/:short" do |short|
  long = $redis.get "short:#{short}"
  $redis.incr(:misses) and nope! unless long

  limited = $redis.exists("short:#{short}:limit") &&
    $redis.decr("short:#{short}:limit") < 0

  if limited
    %W(long:#{long} short:#{short} short:#{short}:limit).each do |key|
      $redis.del key
    end

    nope!
  end

  metrics = $redis.get "metrics:#{short}"

  if metrics.nil? || metrics =~ (/(true|t|yes|y|1)$/i)
    $redis.incr    :hits
    $redis.zincrby "by:hits", 1, short
    $redis.zadd    "by:time", Time.now.utc.to_i, short

    uri = URI.parse(request.referrer)
    url = if uri
      uri.host && !uri.host.empty? ? uri.host : "unknown"
    else
      "unknown"
    end

    $redis.zincrby "#{short}:referrers", 1, url
  end

  redirect long, 301
end

get "/:short/stats" do |short|
  nope! unless @long = $redis.get("short:#{short}")

  @short = short
  @hits  = $redis.zscore("by:hits", short).to_i
  @limit = $redis.get("short:#{short}:limit").to_i
  @time  = $redis.zscore("by:time", short).to_i
  @referrers = Hash[*$redis.zrevrange("#{short}:referrers", 0, 20, :with_scores => true)]

  @title = "Stats :: #@short"
  erb :stat
end
