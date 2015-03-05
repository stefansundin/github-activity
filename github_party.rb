# This is a GitHub party, and everyone's invited!

require "httparty"

class GithubPartyException < Exception
end

class GithubParty
  include HTTParty
  base_uri "https://api.github.com"

  def initialize
    @options = self.class.options
    @ratelimit = nil
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
        @ratelimit = self.class.process(r)
        return nil if r.code == 404
        raise GithubPartyException, self.class.error(r) if not r.success?
        break if r.parsed_response.count == 0

        entries = entries + r.parsed_response.reject { |gist| gist["comments"] == 0 }.map do |gist|
          {
            "id" => gist["id"],
            "comments" => gist["comments"],
          }
        end

        page += 1
      end
      $redis.setex "gists:#{user}", 60*60, entries.to_json
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
        r = self.class.get "/gists/#{gist["id"]}/comments?page=#{page}", @options
        @ratelimit = self.class.process(r)
        raise GithubPartyException, self.class.error(r) if not r.success?
        break if r.parsed_response.count == 0

        comments = comments + r.parsed_response.map do |comment|
          {
            "id" => comment["id"],
            "user" => (comment["user"] ? {
              "login" => comment["user"]["login"],
            } : nil),
            "created_at" => comment["created_at"],
            "updated_at" => comment["updated_at"],
            "body" => comment["body"],
          }
        end

        break if comments.count >= gist["comments"]
        page += 1
      end
      $redis.setex "gist:#{id}", 24*60*60, comments.to_json
      $redis.setex "gist:#{id}:count", 24*60*60, comments.count
    end

    comments
  end

  def finalize
    self.class.finalize(@ratelimit) if @ratelimit
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
    raise GithubPartyException, error(r) if not r.success? or r.parsed_response["error"]
    access_token = r.parsed_response["access_token"]
    $redis.set "access_token", access_token

    r = get "/user", options
    github_username = r.parsed_response["login"]
    $redis.set "login", github_username
    finalize(process(r))
    raise GithubPartyException, error(r) if not r.success?

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

  def self.process(r)
    if r.code == 401
      $redis.del "access_token"
      raise "Access token #{r.request.options[:query][:access_token]} revoked!"
    end
    {
      limit: r.headers["X-RateLimit-Limit"],
      remaining: r.headers["X-RateLimit-Remaining"],
      reset: r.headers["X-RateLimit-Reset"]
    }
  end

  def self.finalize(ratelimit)
    $redis.set "ratelimit-limit", ratelimit[:limit]
    $redis.setex "ratelimit-remaining", ratelimit[:reset], ratelimit[:remaining]
    $redis.setex "ratelimit-reset", ratelimit[:reset], ratelimit[:reset]
  end

  def self.error(r)
    "#{r.request.path.to_s}: #{r.code} #{r.message}: #{r.body}. #{r.headers.to_h.to_json}"
  end
end
