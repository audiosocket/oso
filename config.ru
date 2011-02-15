# This load path manipulation is unnecessary if you're running Oso
# from the released gem.

$:.unshift "lib"

require "oso/server"

set :root, File.expand_path("..", "__FILE__")
run Sinatra::Application
