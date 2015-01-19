require 'dotenv'

if Sinatra::Base.environment != :production
  Dotenv.load '.env'
end
