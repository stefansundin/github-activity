desc "Generate a secure token"
task :secret do
  puts SecureRandom.hex(64)
end
