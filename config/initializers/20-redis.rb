begin
  $redis = Redis.new
rescue => e
  puts "Failed to connect to redis!"
  puts e.backtrace
end
