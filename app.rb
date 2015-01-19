require 'sinatra/base'
require './github_party'

app_path = File.expand_path(File.dirname(__FILE__))
Dir["#{app_path}/config/initializers/*.rb"].each { |f| require f }

def format_date(date)
  date.gsub('T',' ').gsub('Z','')
end

class App < Sinatra::Base
  get '/' do
    "<h1>GitHub activity rss feed</h1>"+
    "<p><form action='/go' method='get'>username: <input type='text' name='username' placeholder='github username' value='stefansundin'> <input type='submit' value='Go'></form></p>"+
    "<p><a href='/stefansundin.xml'>stefansundin</a> <a href='/flush'>flush cache</a></p>"+
    "<p>authenticated? "+($redis.exists('access_token') ? $redis.get('login') : "<a href='/auth'>no</a></p>") +
    "<p>ratelimit: #{GithubParty.ratelimit.to_json}</p>"
  end

  get '/go' do
    redirect "/#{params[:username]}.xml"
  end

  get '/:user.xml' do
    client = GithubParty.new
    user = params[:user]
    gists = client.gists user

    gist_comments = gists.map do |gist|
      comments = client.gist_comments gist
      comments.map do |comment|
        [ gist['id'], comment ]
      end
    end.flatten(1)
    gist_comments.reject! { |id, c| c['user']['login'] == user }
    gist_comments.sort_by! { |id, c| c['created_at'] }
    gist_comments.reverse!

    headers 'Content-Type' => 'application/atom+xml'
    output = []
    output.push <<eos
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>user:#{user}</id>
  <title>#{user} gist comments</title>
  <icon>https://assets-cdn.github.com/favicon.ico</icon>
  <link href="http://stefansundin.com:3000/#{user}.xml" rel="self" />
  <updated>#{gist_comments[0][1]['updated_at'] if gist_comments[0]}</updated>
  <author>
    <name>Stefan Sundin</name>
    <uri>https://stefansundin.com/</uri>
  </author>
eos

    gist_comments.map do |id, c|
      output.push <<eos

  <entry>
    <id>gist:comment:#{c['id']}:#{c['updated_at']}</id>
    <title>Comment by #{c['user']['login']}</title>
    <link href="https://gist.github.com/#{user}/#{id}#comment-#{c['id']}" />
    <updated>#{c['updated_at']}</updated>
    <author><name>#{c['user']['login']}</name></author>
    <content type="html">
&lt;p>User #{c['user']['login']} commented on #{id} at #{format_date(c['created_at'])}:&lt;/p>
&lt;pre>
#{c['body']}
&lt;/pre>
    </content>
  </entry>
eos

    end
    output.push "</feed>\n"
    output.join('')
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
    if ENV['RACK_ENV'] == 'production'
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
end
