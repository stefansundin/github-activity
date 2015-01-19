require 'sinatra'
require './config/application'
require './github_party'
require 'erb'

def format_date(date)
  date.gsub('T',' ').gsub('Z','')
end


get '/' do
  erb :index
end

get '/go' do
  redirect "/#{params[:username]}.xml"
end

get '/:user.xml' do
  client = GithubParty.new
  @user = params[:user]
  gists = client.gists @user

  @gist_comments = gists.map do |gist|
    comments = client.gist_comments gist
    comments.map do |comment|
      [ gist['id'], comment ]
    end
  end.flatten(1)
  @gist_comments.reject! { |id, c| c['user']['login'] == @user }
  @gist_comments.sort_by! { |id, c| c['created_at'] }
  @gist_comments.reverse!

  headers 'Content-Type' => 'application/atom+xml'
  erb :feed
end

get '/flush' do
  $redis.keys.each do |key|
    if not %w[access_token login].include?(key)
      $redis.del key
    end
  end
  redirect '/'
end

get '/flushall' do
  if self.class.environment == :production
    return 'forbidden in production'
  end
  $redis.flushall
  redirect '/'
end

get '/auth' do
  redirect "https://github.com/login/oauth/authorize?client_id=#{ENV['GITHUB_CLIENT_ID']}"
end

get '/callback' do
  return 'already authenticated' if $redis.exists('access_token')
  GithubParty.authenticate(request.env['rack.request.query_hash']['code'])
  redirect '/'
end
