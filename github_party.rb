# This is a GitHub party, and everyone"s invited!

require "httparty"

class GithubParty
  include HTTParty
  base_uri "https://api.github.com"

  def initialize
    @options = self.class.options
  end

  def gists(user)
    redis_data = $redis.get "gists:#{user}"
    if redis_data
      entries = JSON.parse redis_data
    else
      entries = []
      page = 1
      while true
        r = self.class.get "/users/#{URI.encode(user)}/gists?page=#{page}", @options
        self.class.process(r)
        return nil if r.code == 404
        raise self.class.error(r) if not r.success?
        break if r.parsed_response.count == 0
        entries = entries + r.parsed_response
        page += 1
      end
      $redis.set "gists:#{user}", entries.to_json
      $redis.expire "gists:#{user}", 60*60
    end
    entries
  end

  def gist_comments(gist)
    return [] if gist["comments"] == 0

    id = gist["id"]
    redis_count = $redis.get("gist:#{id}:count").to_i
    if redis_count == gist["comments"]
      redis_data = $redis.get "gist:#{id}"
      if redis_data
        comments = JSON.parse redis_data
      end
    end

    if not comments
      comments = []
      page = 1
      while true
        r = self.class.get "#{gist["comments_url"]}?page=#{page}", @options
        self.class.process(r)
        raise self.class.error(r) if not r.success?
        break if r.parsed_response.count == 0
        comments = comments + r.parsed_response
        break if comments.count == gist["comments"]
        page += 1
      end
      $redis.set "gist:#{id}", comments.to_json
      $redis.set "gist:#{id}:count", comments.count
      $redis.expire "gist:#{id}", 24*60*60
    end

    comments
  end

  def self.authenticate(code)
    r = post("https://github.com/login/oauth/access_token",
              query: {
                client_id: ENV["GITHUB_CLIENT_ID"],
                client_secret: ENV["GITHUB_CLIENT_SECRET"],
                code: code
              }, headers: {
                "Accept" => "application/json"
              })
    raise error(r) if not r.success? or r.parsed_response["error"]
    access_token = r.parsed_response["access_token"]
    $redis.set "access_token", access_token

    r = get "/user", options
    github_username = r.parsed_response["login"]
    $redis.set "login", github_username
    process(r)
    raise error(r) if not r.success?

    [ github_username, access_token ]
  end

  def self.ratelimit
    limits = {
      limit: $redis.get("ratelimit-limit"),
      remaining: $redis.get("ratelimit-remaining"),
      reset: $redis.get("ratelimit-reset"),
    }
    limits[:reset] = Time.at(limits[:reset].to_i) if limits[:reset]
    limits
  end

  private

  def self.process(r)
    $redis.set "ratelimit-limit", r.headers["X-RateLimit-Limit"]
    $redis.set "ratelimit-remaining", r.headers["X-RateLimit-Remaining"]
    $redis.set "ratelimit-reset", r.headers["X-RateLimit-Reset"]
    $redis.expireat "ratelimit-remaining", r.headers["X-RateLimit-Reset"]
    $redis.expireat "ratelimit-reset", r.headers["X-RateLimit-Reset"]
    if r.code == 401
      $redis.del "access_token"
      raise "Access token #{r.request.options[:query][:access_token]} revoked!"
    end
  end

  def self.options
    opts = {
      query: {},
      headers: {
        "User-Agent" => "github-activity"
      }
    }
    access_token = ENV["ACCESS_TOKEN"] || $redis.get("access_token")
    opts[:query][:access_token] = access_token if access_token
    opts
  end

  def self.error(r)
    "#{r.request.path.to_s}: #{r.code} #{r.message}: #{r.body}. #{r.headers.to_h.to_json}"
  end
end
