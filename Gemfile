source "https://rubygems.org"

ruby "~> 2.5.0"

gem "rake", require: false
gem "rack"
gem "sinatra"
gem "unicorn"
gem "redis"
gem "httparty"
gem "rack-ssl-enforcer"
gem "clogger"
gem "heroku-env"
gem "encrypted_strings"

group :production do
  gem "airbrake", require: false
  gem "newrelic_rpm", require: false
end

group :development do
  gem "sinatra-reloader"
  gem "powder"
  gem "dotenv"
  gem "binding_of_caller"
  gem "better_errors"
  gem "pry-remote"
  gem "github-release-party"
end
