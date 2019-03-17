source "https://rubygems.org"

ruby ">= 2.6.0"

gem "rake", require: false
gem "rack"
gem "sinatra"
gem "puma"
gem "dotenv"
gem "addressable"
gem "rack-ssl-enforcer"
gem "clogger"
gem "encrypted_strings"
gem "prometheus-client", require: "prometheus/middleware/exporter"

group :production do
  gem "airbrake", require: false
  gem "newrelic_rpm", require: false
end

group :development do
  gem "sinatra-contrib", require: "sinatra/reloader"
  gem "powder"
  gem "binding_of_caller"
  gem "better_errors"
  gem "pry-remote"
  gem "github-release-party"
end
