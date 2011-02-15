require "redis/namespace"
require "new_base_60"
require "sinatra"
require "uri"

url = ENV.values_at("OSO_REDIS_URL", "REDISTOGO_URL").compact.first
url = URI.parse url || "redis://localhost:6379"

$redis = Redis::Namespace.new :oso,
  redis: Redis.new(host: url.host, password: url.password, port: url.port)

get "/" do
  IO.read "public/index.html"
end

get "/stats" do
  @title = "Stats"
  erb :stats
end

post "/" do
  halt [412, {}, "Missing 'url' param."] unless url = params[:url]
  url  = "http://#{url}" unless /^http/i =~ url
  life = params[:life].to_i if params[:life]

  unless short = $redis.get("long:#{url}")
    longkey  = "long:#{url}"
    short    = $redis.incr(:counter).to_sxg
    shortkey = "short:#{short}"

    $redis.multi do
      $redis.set longkey,  short
      $redis.set shortkey, url
    end

    if life
      $redis.expire longkey,  life
      $redis.expire shortkey, life
    end
  end

  request.path_info = "/#{short}"
  [201, {}, request.url]
end

get "/:short" do |short|
  long = $redis.get "short:#{short}"
  halt $redis.incr(:misses) && [404, {}, "No luck."] unless long

  $redis.multi do
    $redis.incr    :hits
    $redis.zincrby "by:hits", 1, short
    $redis.zadd    "by:time", Time.now.utc.to_i, short
  end

  redirect long
end
