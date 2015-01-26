app_path = File.expand_path(File.dirname(__FILE__) + "/..")
Dir["#{app_path}/config/initializers/*.rb"].each { |f| require f }

# development specific
configure :development do
  require "better_errors"
  use BetterErrors::Middleware
  BetterErrors.application_root = File.expand_path("..", __FILE__)
end
