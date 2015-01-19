app_path = File.expand_path(File.dirname(__FILE__) + '/..')
worker_processes 1

#listen app_path + '/tmp/unicorn.sock', backlog: 64
listen 3000, backlog: 64

timeout 60
working_directory app_path
pid app_path+'/tmp/unicorn.pid'
#stderr_path app_path + '/log/unicorn.log'
stdout_path app_path+'/log/unicorn.log'

preload_app true

after_fork do |server, worker|
  $redis.client.reconnect
end
