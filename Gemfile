source "https://rubygems.org"

ruby File.read(".ruby-version").strip

# newer rack has bug with sinatra exceptions
gem "rack", "1.5.2"

gem "unicorn"
gem "sinatra"
gem "redis"
gem "httparty"
gem "airbrake"
gem "rack-ssl-enforcer"

group :development do
  gem "dotenv"
  gem "binding_of_caller"
  gem "better_errors"
end
