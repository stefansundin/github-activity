require 'sinatra/base'

def getsecret
  secret = $redis.get('mykey')
  if secret
    secret
  else
    'nil'
  end
end

class App < Sinatra::Base
  get '/' do
    "<p>This is <i>dynamic</i> content served via unicorn: #{rand(36**6).to_s(36)}<br>"+
    "Redis string: "+getsecret()
  end
end

