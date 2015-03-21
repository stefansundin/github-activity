environment = ENV["RACK_ENV"] || "development"

if environment == "development"
  require "dotenv/tasks"
end

Dir["lib/tasks/*.rake"].each { |f| load f }
