require "sinatra"
require "./config/application"
require "./github_party"
require "erb"

def format_date(date)
  date.gsub("T", " ").gsub("Z", " UTC")
end



get "/" do
  @ratelimit = GithubParty.ratelimit
  erb :index
end

get "/go" do
  params[:username] = "stefansundin" if params[:username].empty?
  redirect "/#{params[:username]}.xml"
end

get "/:user.xml" do
  client = GithubParty.new
  @user = params[:user]
  gists = client.gists @user

  return "Unfortunately there does not seem to be a user with the name #{@user}." if gists.nil?

  @gist_comments = gists.map do |gist|
    comments = client.gist_comments gist
    comments.map do |comment|
      [ gist["id"], comment ]
    end
  end.flatten(1)

  # write the latest ratelimit values to redis
  client.finalize

  # remove your own comments, then sort
  # c["user"] can be null, I think this is if a user was deleted
  @gist_comments.reject! { |id, c| c["user"]["login"] == @user rescue true }
  @gist_comments.sort_by! { |id, c| c["created_at"] }.reverse!

  headers "Content-Type" => "application/atom+xml;charset=utf-8"
  erb :feed
end

get "/flush" do
  $redis.keys.each do |key|
    $redis.del key if key.start_with?("gist")
  end
  "Cache cleared"
end

get "/flushall" do
  if self.class.environment == :production
    return "forbidden in production"
  end
  $redis.flushall
end

get "/auth" do
  redirect "https://github.com/login/oauth/authorize?client_id=#{ENV["GITHUB_CLIENT_ID"]}"
end

get "/callback" do
  return "already authenticated" if ENV["ACCESS_TOKEN"] or $redis.exists("access_token")
  github_username, access_token = GithubParty.authenticate(request.env["rack.request.query_hash"]["code"])

  headers "Content-Type" => "text/plain"
  "Welcome #{github_username}. Your access token is stored in redis. You might want to store it in ENV instead:\n\nheroku config:set ACCESS_TOKEN=#{access_token}"
end

get "/favicon.ico" do
  redirect "/img/icon32.png"
end

get %r{^/apple-touch-icon} do
  redirect "/img/icon128.png"
end

get "/robots.txt" do
  # only allow root to be indexed
  headers "Content-Type" => "text/plain"
  <<eos
User-agent: *
Allow: /$
Disallow: /
eos
end

get %r{^/loaderio-c8b2f36404a8cc878bdd10a682ead986} do
  headers "Content-Type" => "text/plain"
  "loaderio-c8b2f36404a8cc878bdd10a682ead986"
end

get "/googlecd2a49223a3e752f.html" do
  "google-site-verification: googlecd2a49223a3e752f.html"
end

post %r{/xmlrpc} do
  raise "PINGBACK_EMAIL not configured" unless ENV["PINGBACK_EMAIL"]

  Pingback::Server.new(Proc.new { |source_uri, target_uri|
    Mail.deliver do
         from "Pingback <#{ENV["MAIL_FROM"]}>"
           to ENV["PINGBACK_EMAIL"]
      subject "New pingback for #{target_uri}"
         body "Pingback to #{target_uri} from #{source_uri}"
    end
  }).call(env)
end


error do
  "Sorry, a nasty error occurred: #{env["sinatra.error"].name}"
end

error GithubPartyException do
  "There was a problem talking to GitHub."
end
