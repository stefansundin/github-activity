# This is a GitHub party, and everyone's invited!

require "httparty"

class GithubPartyError < StandardError
  def initialize(request)
    @request = request
  end

  def request
    @request
  end
end

class TokenRevokedError < GithubPartyError; end


class GithubParty
  include HTTParty
  base_uri "https://api.github.com"

  def initialize(access_token=nil)
    @access_token = access_token
    @ratelimit = nil
  end

  def gists(user)
    redis_data = $redis.get "gists:#{user}"
    if redis_data
      return JSON.parse(redis_data)
    end

    entries = []
    page = 1
    while true
      r = self.class.get "/users/#{URI.encode(user)}/gists?page=#{page}", options
      process(r)
      return nil if r.code == 404
      raise GithubPartyError, self.class.error(r) if not r.success?
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
        r = self.class.get "/gists/#{gist["id"]}/comments?page=#{page}", options
        process(r)
        raise GithubPartyError, self.class.error(r) if not r.success?
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
    return if @ratelimit.nil?
    $redis.set "ratelimit-limit", @ratelimit[:limit]
    $redis.set "ratelimit-remaining", @ratelimit[:remaining]
    $redis.set "ratelimit-reset", @ratelimit[:reset]
    $redis.expireat "ratelimit-remaining", @ratelimit[:reset].to_i
    $redis.expireat "ratelimit-reset", @ratelimit[:reset].to_i
  end

  def username
    redis_data = $redis.get "username:#{@access_token}"
    if redis_data
      return redis_data
    end

    r = self.class.get "/user", options
    raise GithubPartyError, self.class.error(r) if not r.success?
    login = r.parsed_response["login"]
    $redis.setex "username:#{@access_token}", 60*60, login
    login
  end

  def my_gists
    redis_data = $redis.get "gists:token:#{@access_token}"
    if redis_data
      return JSON.parse(redis_data)
    end

    entries = []
    page = 1
    while true
      r = self.class.get "/gists?page=#{page}", options
      process(r)
      return nil if r.code == 404
      raise GithubPartyError, self.class.error(r) if not r.success?
      break if r.parsed_response.count == 0

      entries = entries + r.parsed_response.reject { |gist| gist["comments"] == 0 }.map do |gist|
        {
          "id" => gist["id"],
          "comments" => gist["comments"],
        }
      end

      page += 1
    end
    $redis.setex "gists:token:#{@access_token}", 60*60, entries.to_json
    entries
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
    raise GithubPartyError.new(r) if not r.success? or r.parsed_response["error"]
    r.parsed_response["access_token"]
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

  def options
    opts = {
      query: {},
      headers: {
        "User-Agent" => "github-activity"
      }
    }
    if @access_token
      opts[:query][:access_token] = @access_token
    elsif ENV["GITHUB_CLIENT_ID"] and ENV["GITHUB_CLIENT_SECRET"]
      opts[:query][:client_id] = ENV["GITHUB_CLIENT_ID"]
      opts[:query][:client_secret] = ENV["GITHUB_CLIENT_SECRET"]
    end
    opts
  end

  def process(r)
    if r.code == 401
      raise TokenRevokedError.new(r)
    end
    @ratelimit = {
      limit: r.headers["X-RateLimit-Limit"],
      remaining: r.headers["X-RateLimit-Remaining"],
      reset: r.headers["X-RateLimit-Reset"]
    }
  end

  def self.error(r)
    "#{r.request.path.to_s}: #{r.code} #{r.message}: #{r.body}. #{r.headers.to_h.to_json}"
  end
end
