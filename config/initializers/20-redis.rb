begin
  $redis = Redis::Namespace.new :github_activity
rescue => e
  puts "Failed to connect to redis!"
  puts e.backtrace
end
