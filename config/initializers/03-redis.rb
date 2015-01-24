require "redis"

ENV["REDIS_URL"] ||= ENV["REDISCLOUD_URL"] || ENV["REDISTOGO_URL"]

$redis = Redis.new path: ENV["REDIS_SOCKET"]
