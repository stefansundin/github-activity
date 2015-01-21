if Sinatra::Base.environment == :development
  require 'dotenv'
  Dotenv.load '.env'
end
