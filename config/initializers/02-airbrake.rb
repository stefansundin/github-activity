require 'airbrake'

if ENV['AIRBRAKE_KEY']
  Airbrake.configure do |config|
    config.host = ENV['AIRBRAKE_HOST']
    config.api_key = ENV['AIRBRAKE_KEY']
    config.secure = true
    # config.development_environments = []
  end
end
