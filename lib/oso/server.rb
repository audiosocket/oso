require "redis/namespace"
require "new_base_60"
require "sinatra"
require "uri"

url = ENV.values_at("OSO_REDIS_URL", "REDISTOGO_URL").compact.first
url = URI.parse url || "redis://localhost:6379"

$redis = Redis::Namespace.new :oso,
  redis: Redis.new(host: url.host, password: url.password, port: url.port)

helpers do
  def nope!
    halt 404, {}, "No luck."
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
  @byhits  = Hash[*$redis.zrevrange("by:hits", 0, 10, :with_scores => true)]
  @bytimes = Hash[*$redis.zrevrange("by:time", 0, 10, :with_scores => true)]

  [@byhits, @bytimes].each do |h|
    h.each { |k, v| h[k] = { long: $redis.get("short:#{k}"), score: v }  }
  end

  @title = "Stats"
  erb :stats
end

post "/" do
  halt [412, {}, "Missing 'url' param."] unless url = params[:url]

  url = "http://#{url}" unless /^http/i =~ url

  life  = params[:life].to_i  if params[:life]
  limit = params[:limit].to_i if params[:limit]

  unless short = $redis.get("long:#{url}")
    longkey  = "long:#{url}"
    short    = $redis.incr(:counter).to_sxg
    shortkey = "short:#{short}"
    limitkey = "#{shortkey}:limit"

    $redis.multi do
      $redis.set limitkey, limit if limit
      $redis.set longkey,  short
      $redis.set shortkey, url
    end

    if life
      $redis.expire limitkey, limit if limit
      $redis.expire longkey,  life
      $redis.expire shortkey, life
    end
  end

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

  $redis.incr    :hits
  $redis.zincrby "by:hits", 1, short
  $redis.zadd    "by:time", Time.now.utc.to_i, short

  redirect long
end
