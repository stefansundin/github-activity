# frozen_string_literal: true

ENV["APP_ENV"] ||= "development"

require "bundler/setup"
Bundler.require(:default, ENV["APP_ENV"])

configure do
  use Rack::Deflater, sync: false
  use Rack::SslEnforcer, only_hosts: /\.herokuapp\.com$/
  use Prometheus::Middleware::Exporter
  set :erb, trim: "-"
  # Look up Rack::Mime::MIME_TYPES to see rack defaults
  mime_type :opensearch, "application/opensearchdescription+xml"
  settings.add_charset << "application/atom+xml"
end

configure :development do
  if defined?(BetterErrors)
    use BetterErrors::Middleware
    BetterErrors.application_root = File.expand_path("..")
  end
end

app_path = File.expand_path("../..", __FILE__)
Dir["#{app_path}/config/initializers/*.rb"].each { |f| require f }
Dir["#{app_path}/lib/*.rb"].each { |f| require f }
Dir["#{app_path}/app/**/*.rb"].each { |f| require f }
