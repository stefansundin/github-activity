# This is a GitHub party, and everyone's invited!

require "httparty"

class GithubReleaseParty
  include HTTParty
  base_uri "https://api.github.com"

  def initialize
    @releases = []
    repo = self.class.owner_and_repo
    page = 1
    while true
      r = self.class.get "/repos/#{repo}/releases?page=#{page}", self.class.options
      raise self.class.error(r) if not r.success?
      break if r.parsed_response.count == 0

      @releases = @releases + r.parsed_response
      page += 1
    end
  end

  def update_or_create(tag_name, name, message)
    release = @releases.find { |rel| rel["tag_name"] == tag_name }
    if release
      self.class.update(release["id"], name, message)
    else
      self.class.create(tag_name, name, message)
    end
  end

  def self.update(id, name, message)
    r = patch "/repos/#{owner_and_repo}/releases/#{id}", options.merge({
      body: {
        name: name,
        body: message
      }.to_json
    })
    if r.success?
      puts "GitHub release #{name} updated!"
    else
      puts "Failed to update GitHub release!"
      puts error(r)
    end
  end

  def self.create(tag_name, name, message)
    unless ENV["GITHUB_RELEASE_TOKEN"]
      puts "Configure GITHUB_RELEASE_TOKEN to create GitHub releases."
      return
    end

    r = post "/repos/#{owner_and_repo}/releases", options.merge({
      body: {
        tag_name: tag_name,
        name: name,
        body: message
      }.to_json
    })
    if r.success?
      puts "GitHub release #{tag_name} created!"
    else
      puts "Failed to create GitHub release!"
      puts error(r)
    end
  end

  private

  def self.owner_and_repo
    `git remote -v`.scan(/^origin\t.*github.com:(.+)\.git /).uniq.flatten.first
  end

  def self.options
    {
      query: {
        access_token: ENV["GITHUB_RELEASE_TOKEN"]
      },
      headers: {
        "User-Agent" => "github-activity"
      }
    }
  end

  def self.error(r)
    "#{r.request.path.to_s}: #{r.code} #{r.message}: #{r.body}. #{r.headers.to_h.to_json}"
  end
end

