# frozen_string_literal: true

desc "Generate a secure token"
task :secret do
  require "securerandom"
  puts SecureRandom.hex(64)
end
