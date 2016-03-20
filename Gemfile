source "https://rubygems.org"

ruby File.read(".ruby-version").strip

gem "rack"
gem "sinatra"
gem "unicorn"
gem "redis"
gem "httparty"
gem "airbrake"
gem "rack-ssl-enforcer"
gem "clogger"
gem "heroku-env"
gem "encrypted_strings"

group :production do
  gem "newrelic_rpm"
end

group :development do
  gem "rake"
  gem "sinatra-reloader"
  gem "powder"
  gem "dotenv"
  gem "binding_of_caller"
  gem "better_errors"
  gem "pry-remote"
  gem "github-release-party"
end
