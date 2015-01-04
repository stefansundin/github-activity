require 'redis'

$redis = Redis.new path: ENV["REDIS_SOCKET"]

