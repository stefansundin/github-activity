# frozen_string_literal: true
# export RUBYOPT=--enable-frozen-string-literal

require "sinatra"
require "./config/application"

def format_date(date)
  date.gsub("T", " ").gsub("Z", " UTC")
end

before do
  content_type :text
end

if ENV["BING_VERIFICATION_TOKEN"]
  get "/BingSiteAuth.xml" do
    content_type :xml
    <<~EOF
      <?xml version="1.0"?>
      <users>
        <user>#{ENV["BING_VERIFICATION_TOKEN"]}</user>
      </users>
    EOF
  end
end

get "/" do
  erb :index
end

get "/go" do
  response = GitHub.graphql(:get_user, {
    "user": params[:q].presence || "stefansundin",
  })
  raise(GitHubError, response) if !response.success?
  data = response.json

  if data["errors"]
    status 400
    return data["errors"][0]["message"]
  end

  redirect "/#{data["data"]["user"]["login"]}.xml"
end

get "/:user.xml" do |user|
  response = GitHub.graphql(:first_page, {
    user: user,
  })
  raise(GitHubError, response) if !response.success?
  data = response.json

  if data["errors"]
    status 400
    return data["errors"][0]["message"]
  end

  @user = data["data"]["user"]["login"]
  @comments = GitHub.process_gists(data["data"]["user"]["gists"], @user)

  while data["data"]["user"]["gists"]["pageInfo"]["hasNextPage"]
    response = GitHub.graphql(:next_page, {
      user: @user,
      cursor: data["data"]["user"]["gists"]["pageInfo"]["endCursor"],
    })
    data = response.json
    if data["errors"]
      status 400
      return data["errors"][0]["message"]
    end
    @comments.push(*GitHub.process_gists(data["data"]["user"]["gists"], @user))
  end
  @comments = @comments.sort_by { |c| c["updated_at"] }.reverse[0...20]

  erb :feed
end

get "/token/*" do
  token = env["REQUEST_PATH"]["/token/".length..]
  begin
    access_token = token.decrypt(:symmetric, password: ENV["ENCRYPTION_KEY"])
  rescue
    status 400
    return "Could not decrypt token, sorry."
  end

  # https://github.blog/2021-04-05-behind-githubs-new-authentication-token-formats/
  if !access_token.start_with?("gho_")
    status 400
    return "This URL is using a legacy token. Please re-authenticate and use the new URL."
  end

  response = GitHub.graphql(:authed_first_page, nil, access_token)
  if response.code == 401
    status response.code
    return "The token does not seem to work, did you revoke it?"
  end
  raise(GitHubError, response) if !response.success?
  data = response.json

  if data["errors"]
    status 400
    return data["errors"][0]["message"]
  end

  @user = data["data"]["viewer"]["login"]
  @comments = GitHub.process_gists(data["data"]["viewer"]["gists"], @user)

  while data["data"]["viewer"]["gists"]["pageInfo"]["hasNextPage"]
    response = GitHub.graphql(:authed_next_page, {
      cursor: data["data"]["viewer"]["gists"]["pageInfo"]["endCursor"],
    }, access_token)
    raise(GitHubError, response) if !response.success?
    data = response.json
    if data["errors"]
      status 400
      return data["errors"][0]["message"]
    end
    @comments.push(*GitHub.process_gists(data["data"]["viewer"]["gists"], @user))
  end
  @comments = @comments.sort_by { |c| c["updated_at"] }.reverse[0...20]

  erb :feed
end

get "/auth" do
  headers({"X-Robots-Tag" => "noindex"})
  redirect "https://github.com/login/oauth/authorize?client_id=#{ENV["GITHUB_CLIENT_ID"]}&scope=gist"
end

get "/callback" do
  response = GitHub.authenticate(request.env["rack.request.query_hash"]["code"])
  raise(GitHubError, response) if !response.success? || response.json["error"]
  access_token = response.json["access_token"]

  response = GitHub.graphql(:whoami, nil, access_token)
  raise(GitHubError, response) if !response.success?
  @username = response.json["data"]["viewer"]["login"]

  encrypted_token = access_token.encrypt(:symmetric, password: ENV["ENCRYPTION_KEY"]).gsub("\n", "")
  @url = "#{request.base_url}/token/#{encrypted_token}"

  erb :authed
end

get "/favicon.ico" do
  redirect "/img/icon32.png"
end

get %r{/apple-touch-icon.+} do
  redirect "/img/icon128.png"
end

get "/opensearch" do
  erb :opensearch
end

if ENV["GOOGLE_VERIFICATION_TOKEN"]
  /(google)?(?<google_token>[0-9a-f]+)(\.html)?/ =~ ENV["GOOGLE_VERIFICATION_TOKEN"]
  get "/google#{google_token}.html" do
    "google-site-verification: google#{google_token}.html"
  end
end

error do
  status 500
  "Sorry, a nasty error occurred: #{env["sinatra.error"].message}"
end

not_found do
  "Sorry, that route does not exist."
end
