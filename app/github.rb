# frozen_string_literal: true
# https://developer.github.com/v4/explorer/
# https://developer.github.com/v4/object/gistcomment/
# https://developer.github.com/v4/changelog/
# At the moment, anonymous access to the GraphQL API is not available:
# https://platform.github.community/t/permit-access-without-oauth-token/2572

class GitHubError < HTTPError; end

class GitHub
  QUERIES = {
    get_user: <<~EOF.delete(" "),
      query ($user: String!) {
        user(login: $user) {
          login
        }
        rateLimit {
          remaining
        }
      }
    EOF
    whoami: <<~EOF.delete(" "),
      query {
        viewer {
          login
        }
        rateLimit {
          remaining
        }
      }
    EOF
    first_page: <<~EOF.delete(" "),
      query ($user: String!) {
        user(login: $user) {
          login
          gists(first: 100) {
            pageInfo {
              hasNextPage
              endCursor
            }
            nodes {
              comments(last: 5) {
                nodes {
                  id
                  createdAt
                  lastEditedAt
                  body
                  author {
                    login
                  }
                }
              }
            }
          }
        }
        rateLimit {
          remaining
        }
      }
    EOF
    next_page: <<~EOF.delete(" "),
      query ($user: String!, $cursor: String!) {
        user(login: $user) {
          gists(first: 100, after: $cursor) {
            pageInfo {
              hasNextPage
              endCursor
            }
            nodes {
              comments(last: 5) {
                nodes {
                  id
                  createdAt
                  lastEditedAt
                  body
                  author {
                    login
                  }
                }
              }
            }
          }
        }
        rateLimit {
          remaining
        }
      }
    EOF
    authed_first_page: <<~EOF.delete(" "),
      query {
        viewer {
          login
          gists(first: 100, privacy: ALL) {
            pageInfo {
              hasNextPage
              endCursor
            }
            nodes {
              comments(last: 5) {
                nodes {
                  id
                  createdAt
                  lastEditedAt
                  body
                  author {
                    login
                  }
                }
              }
            }
          }
        }
        rateLimit {
          remaining
        }
      }
    EOF
    authed_next_page: <<~EOF.delete(" "),
      query ($cursor: String!) {
        viewer {
          gists(first: 100, privacy: ALL, after: $cursor) {
            pageInfo {
              hasNextPage
              endCursor
            }
            nodes {
              comments(last: 5) {
                nodes {
                  id
                  createdAt
                  lastEditedAt
                  body
                  author {
                    login
                  }
                }
              }
            }
          }
        }
        rateLimit {
          remaining
        }
      }
    EOF
  }

  def self.graphql(query, variables, token=nil)
    url = "https://api.github.com/graphql"
    uri = Addressable::URI.parse(url).normalize
    opts = {
      use_ssl: uri.scheme == "https",
      open_timeout: 10,
      read_timeout: 10,
    }
    Net::HTTP.start(uri.host, uri.port, opts) do |http|
      headers = {
        "User-Agent" => "github-activity",
        "Authorization" => "bearer #{token || ENV["GITHUB_TOKEN"]}",
      }
      raw_response = http.request_post(uri.request_uri, {
        query: self::QUERIES[query],
        variables: variables,
      }.to_json, headers)
      response = HTTPResponse.new(raw_response, uri.to_s)
      if response.json && response.json["data"] && response.json["data"]["rateLimit"] && response.json["data"]["rateLimit"]["remaining"]
        $metrics[:ratelimit_remaining].set(response.json["data"]["rateLimit"]["remaining"])
      end
      return response
    end
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, OpenSSL::SSL::SSLError, EOFError
    raise(GitHubError, $!)
  end

  def self.authenticate(code)
    url = "https://github.com/login/oauth/access_token?client_id=#{ENV["GITHUB_CLIENT_ID"]}&client_secret=#{ENV["GITHUB_CLIENT_SECRET"]}&code=#{code}"
    uri = Addressable::URI.parse(url).normalize
    opts = {
      use_ssl: uri.scheme == "https",
      open_timeout: 10,
      read_timeout: 10,
    }
    Net::HTTP.start(uri.host, uri.port, opts) do |http|
      headers = {
        "User-Agent" => "github-activity",
        "Accept" => "application/json",
      }
      response = http.request_post(uri.request_uri, nil, headers)
      return HTTPResponse.new(response, uri.to_s)
    end
  rescue Net::OpenTimeout, Net::ReadTimeout, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH, OpenSSL::SSL::SSLError, Zlib::BufError, EOFError, ArgumentError
    raise(GitHubError, $!)
  end

  def self.process_gists(gists, user)
    gists["nodes"].map do |gist|
      gist["comments"]["nodes"].reject do |comment|
        # author can be null.. probably if a user was deleted
        comment["author"] != nil && comment["author"]["login"] == user
      end
    end.flatten.each do |comment|
      if comment["author"] == nil
        comment["author"] = {}
      end
      comment["lastEditedAt"] ||= comment["createdAt"]
      comment["updated_at"] = Time.parse(comment["lastEditedAt"])
      comment["id"] = Base64.decode64(comment["id"])
      # example id: 011:GistCommenta99bbfb6cda873d14fd2:2386850
      id_parts = comment["id"].split(":")
      comment["gist_id"] = id_parts[1]["GistComment".length..-1]
      comment["comment_id"] = id_parts[2]
    end
  end
end

error GitHubError do |e|
  status 503
  "There was a problem talking to GitHub. Please try again in a moment."
end
