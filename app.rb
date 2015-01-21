require 'sinatra'
require './config/application'
require './github_party'
require 'erb'

def format_date(date)
  date.gsub('T',' ').gsub('Z',' UTC')
end


get '/' do
  @ratelimit = GithubParty.ratelimit
  erb :index
end

get '/go' do
  params[:username] = 'stefansundin' if params[:username] == ''
  redirect "/#{params[:username]}.xml"
end

get '/:user.xml' do
  client = GithubParty.new
  @user = params[:user]
  gists = client.gists @user
  return "Unfortunately there does not seem to be a user with the name #{@user}." if gists.nil?

  @gist_comments = gists.map do |gist|
    comments = client.gist_comments gist
    comments.map do |comment|
      [ gist['id'], comment ]
    end
  end.flatten(1)

  # remove your own comments, then sort
  # c['user'] can be null, I think this is if a user was deleted
  @gist_comments.reject! { |id, c| c['user']['login'] == @user rescue true }
  @gist_comments.sort_by! { |id, c| c['created_at'] }
  @gist_comments.reverse!

  headers 'Content-Type' => 'application/atom+xml'
  erb :feed
end

get '/flush' do
  $redis.keys.each do |key|
    $redis.del key if key.start_with?('gist')
  end
  "Cache cleared"
end

get '/flushall' do
  if self.class.environment == :production
    return 'forbidden in production'
  end
  $redis.flushall
end

get '/auth' do
  redirect "https://github.com/login/oauth/authorize?client_id=#{ENV['GITHUB_CLIENT_ID']}"
end

get '/callback' do
  return 'already authenticated' if $redis.exists('access_token')
  GithubParty.authenticate(request.env['rack.request.query_hash']['code'])
  redirect '/'
end

get '/favicon.ico' do
  redirect "https://stefansundin.github.io/github-activity/img/icon32.png"
end
