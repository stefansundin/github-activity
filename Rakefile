environment = ENV["RACK_ENV"] || "development"

if environment == "development"
  require "dotenv"
  Dotenv.load ".env"
end

Dir["lib/tasks/*.rake"].each { |f| load f }
