timeout          Integer(ENV["WEB_TIMEOUT"] || 25)
preload_app      true

before_fork do |server, worker|
  Signal.trap "TERM" do
    Process.kill "QUIT", Process.pid
  end
end

after_fork do |server, worker|
  Signal.trap "TERM" do
  end
end
