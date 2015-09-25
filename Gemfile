source "https://rubygems.org"

ruby File.read(".ruby-version").strip

gem "rack"
gem "sinatra"
gem "bundler"
gem "unicorn"
gem "redis"
gem "redis-namespace"
gem "httparty"
gem "airbrake"
gem "newrelic_rpm"
gem "rack-ssl-enforcer"
gem "clogger"
gem "mail"
gem "heroku-env"
gem "encrypted_strings"

# nokogiri 1.6.6.2 is not compatible with Cygwin
gem "nokogiri", "1.6.7.rc3"

source "https://repo.fury.io/stefansundin/" do
  gem "pingback"
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
