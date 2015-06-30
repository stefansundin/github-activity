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
  params[:q] = "stefansundin" if params[:q].empty?
  redirect "/#{params[:q]}.xml"
end

get "/:user.xml" do |user|
  client = GithubParty.new
  @user = user
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

get "/token/*" do |token|
  begin
    access_token = token.decrypt(:symmetric, password: ENV["ENCRYPTION_KEY"])
  rescue
    return "Could not decrypt token, sorry."
  end
  begin
    client = GithubParty.new(access_token)
    @user = client.username
    gists = client.my_gists

    @gist_comments = gists.map do |gist|
      comments = client.gist_comments gist
      comments.map do |comment|
        [ gist["id"], comment ]
      end
    end.flatten(1)

    # remove your own comments, then sort
    # c["user"] can be null, I think this is if a user was deleted
    @gist_comments.reject! { |id, c| c["user"]["login"] == @user rescue true }
    @gist_comments.sort_by! { |id, c| c["created_at"] }.reverse!

    headers "Content-Type" => "application/atom+xml;charset=utf-8"
    erb :feed
  rescue TokenRevokedError => e
    status 401
    return "The token does not seem to work, did you revoke it?"
  end
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
  redirect "https://github.com/login/oauth/authorize?client_id=#{ENV["GITHUB_CLIENT_ID"]}&scope=gist"
end

get "/callback" do
  begin
    access_token = GithubParty.authenticate(request.env["rack.request.query_hash"]["code"])
  rescue GithubPartyError => e
    return e.request.parsed_response["error_description"]
  end

  client = GithubParty.new(access_token)
  @username = client.username

  encrypted_token = access_token.encrypt(:symmetric, password: ENV["ENCRYPTION_KEY"]).gsub("\n", "")
  @url = "#{request.base_url}/token/#{encrypted_token}"

  erb :authed
end

get "/favicon.ico" do
  redirect "/img/icon32.png"
end

get %r{^/apple-touch-icon} do
  redirect "/img/icon128.png"
end

get "/opensearch" do
  headers "Content-Type" => "application/opensearchdescription+xml"
  <<-EOF
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/" xmlns:moz="http://www.mozilla.org/2006/browser/search/">
  <ShortName>GitHub Activity RSS Feed</ShortName>
  <Description>GitHub Activity RSS Feed</Description>
  <InputEncoding>UTF-8</InputEncoding>
  <Image width="16" height="16" type="image/x-icon">#{request.base_url}/favicon.ico</Image>
  <Url type="text/html" method="get" template="#{request.base_url}/go?q={searchTerms}" />
</OpenSearchDescription>
EOF
end

if ENV["GOOGLE_VERIFICATION_TOKEN"]
  /(google)?(?<google_token>[0-9a-f]+)(\.html)?/ =~ ENV["GOOGLE_VERIFICATION_TOKEN"]
  get "/google#{google_token}.html" do
    "google-site-verification: google#{google_token}.html"
  end
end

if ENV["LOADERIO_VERIFICATION_TOKEN"]
  /(loaderio-)?(?<loaderio_token>[0-9a-f]+)/ =~ ENV["LOADERIO_VERIFICATION_TOKEN"]
  get Regexp.new("^/loaderio-#{loaderio_token}") do
    headers "Content-Type" => "text/plain"
    "loaderio-#{loaderio_token}"
  end
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
  status 500
  "Sorry, a nasty error occurred: #{env["sinatra.error"].message}"
end

error GithubPartyError do
  status 503
  "There was a problem talking to GitHub."
end
