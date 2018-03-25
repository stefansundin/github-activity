# frozen_string_literal: true

ENV["APP_ENV"] ||= "development"

if ENV["APP_ENV"] == "development"
  require "github-release-party/tasks/heroku"
end

Dir["lib/tasks/*.rake"].each { |f| load f }
