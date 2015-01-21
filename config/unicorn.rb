worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)
timeout 60
preload_app true

# app_path = File.expand_path(File.dirname(__FILE__) + '/..')
# listen app_path + '/tmp/unicorn.sock', backlog: 64
# listen 3000, backlog: 64

# working_directory app_path
# pid app_path + '/tmp/unicorn.pid'
# stdout_path app_path + '/log/unicorn-stdout.log'
# stderr_path app_path + '/log/unicorn-stderr.log'


before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  $redis.client.reconnect
end
