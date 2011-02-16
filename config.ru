# This load path manipulation is unnecessary if you're running Oso
# from the released gem.

$:.unshift "lib"
require "oso/server"

run Sinatra::Application
