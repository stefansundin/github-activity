# frozen_string_literal: true

require "net/http"

class HTTPResponse
  def initialize(response, url)
    @response = response
    @url = url
  end

  def raw
    @response
  end

  def url
    @url
  end

  def body
    @response.body
  end

  def json
    @json ||= JSON.parse(@response.body)
  end

  def parsed_response
    json
  end

  def headers
    @response.to_hash
  end

  def code
    @response.code.to_i
  end

  def success?
    @response.is_a?(Net::HTTPSuccess)
  end

  def redirect?
    @response.is_a?(Net::HTTPRedirection)
  end

  def redirect_url
    raise("not a redirect") if !redirect?
    url = @response.header["location"]
    if url[0] == "/"
      # relative redirect
      uri = Addressable::URI.parse(@url)
      url = uri.scheme + "://" + uri.host + url
    elsif /^https?:\/\/./ !~ url
      raise("bad redirect: #{url}")
    end
    Addressable::URI.parse(url).normalize.to_s # Some redirects do not url encode properly, such as http://amzn.to/2aDg49F
  end

  def redirect_same_origin?
    return false if !redirect?
    uri = Addressable::URI.parse(@url).normalize
    new_uri = Addressable::URI.parse(redirect_url).normalize
    uri.origin == new_uri.origin
  end
end

class HTTPError < StandardError
  def initialize(obj)
    @obj = obj
  end

  def request
    @obj
  end

  def data
    @obj.json
  end

  def message
    if @obj.is_a?(HTTPResponse)
      "#{@obj.code}: #{@obj.body}"
    else
      @obj.inspect
    end
  end
end
