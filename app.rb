require 'sinatra/base'
require 'httparty'

def httparty_error(r)
  "<a href='#{r.request.path.to_s}'>#{r.request.path.to_s}</a>: #{r.code} #{r.message}: #{r.body}. #{r.headers.to_h.to_json}"
end

def get_gists(user)
  redis_data = $redis.get 'gists'
  comments = []
  if redis_data
    entries = JSON.parse redis_data
  else
    page = 1
    entries = []
    while true
      r = HTTParty.get "https://api.github.com/users/#{user}/gists?page=#{page}"
      return httparty_error(r) unless r.success?
      http_json = JSON.parse r.body
      break if http_json.count == 0
      entries = entries + http_json
      page += 1
    end
    $redis.set 'gists', entries.to_json
    $redis.expire 'gists', 60*60
  end
  entries
end

def get_comments(gists)
  gists.map do |gist|
    id = gist['id']
    redis_data = $redis.get "gist:#{id}"
    if redis_data
      comments = JSON.parse redis_data
    else
      r = HTTParty.get gist['comments_url']
      return httparty_error(r) unless r.success?
      comments = JSON.parse r.body
      $redis.set "gist:#{id}", comments.to_json
      $redis.expire "gist:#{id}", 60*30
    end

    comments.map do |c|
      [ id, c ]
    end
  end.flatten(1).sort_by { |id, c| c['created_at'] }.reverse!
end

class App < Sinatra::Base
  get '/' do
    "<a href='/gists/stefansundin.xml'>stefansundin</a> <a href='/flushall'>flush cache</a>"
  end

  get '/gists/:user.xml' do
    user = params[:user]
    gists = get_gists user
    #return gists.to_json
    return "Error: #{gists}" if gists.is_a? String
    comments = get_comments gists
    #return comments.to_json
    return "Error: #{comments}" if comments.is_a? String
    comments.delete_if { |id, c| c['user']['login'] == user }

    headers 'Content-Type' => 'application/atom+xml'
    output = []
    output.push <<eos
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <id>gist:#{user}</id>
  <title>#{user} gist comments</title>
  <icon>https://assets-cdn.github.com/favicon.ico</icon>
  <link href="http://stefansundin.com:3000/gists/#{user}" rel="self" />
  <updated>#{comments[0][1]['updated_at'] if comments[0]}</updated>
  <author>
    <name>Stefan Sundin</name>
    <uri>https://stefansundin.com/</uri>
  </author>
eos

    comments.map do |id, c|
      output.push <<eos

  <entry>
    <id>gist:comment:#{c['id']}:#{c['updated_at']}</id>
    <title>Comment by #{c['user']['login']}</title>
    <link href="https://gist.github.com/#{user}/#{id}#comment-#{c['id']}" />
    <updated>#{c['updated_at']}</updated>
    <author><name>#{c['user']['login']}</name></author>
    <content type="html">
&lt;p>User #{c['user']['login']} commented on #{id} at #{c['created_at']}:&lt;/p>
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

  get '/flushall' do
    $redis.flushall
  end
end

