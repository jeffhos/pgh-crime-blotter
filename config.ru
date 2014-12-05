require './app'
require 'rack/contrib'

use Rack::TryStatic, :urls => ['/', '/js', '/css'], :root => 'public', :index => 'index.html'

run Blotter::API
