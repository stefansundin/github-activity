# frozen_string_literal: true

ENV["APP_ENV"] ||= "development"

require "bundler/setup"
Bundler.require(:default, ENV["APP_ENV"])

configure do
  set :erb, trim: "-"
  # Look up Rack::Mime::MIME_TYPES to see rack defaults
  mime_type :opensearch, "application/opensearchdescription+xml"
  settings.add_charset << "application/atom+xml"
end

# development specific
configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = File.expand_path(".")
end

app_path = File.expand_path("../..", __FILE__)
Dir["#{app_path}/config/initializers/*.rb"].each { |f| require f }
