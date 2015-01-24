require "rack/ssl-enforcer"
use Rack::SslEnforcer, only_hosts: /\.herokuapp\.com$/
