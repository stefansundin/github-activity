# frozen_string_literal: true

begin
  $redis = Redis.new
rescue => e
  puts "Failed to connect to redis!"
end
