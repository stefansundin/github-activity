# frozen_string_literal: true

ENV["APP_ENV"] ||= "development"
environment(ENV["APP_ENV"])

if ENV["APP_ENV"] == "development" && !ENV["WEB_CONCURRENCY"]
  # better_errors and binding_of_caller works better with only one process and thread
  threads(1, 1)
end

preload_app!

app_path = File.expand_path("../..", __FILE__)
pidfile("#{app_path}/tmp/puma.pid")
bind("unix://#{app_path}/tmp/puma.sock")

if ENV["PORT"]
  port(ENV["PORT"])
end

if ENV["LOG_ENABLED"]
  stdout_redirect("#{app_path}/log/puma-stdout.log", "#{app_path}/log/puma-stderr.log", true)
end

if ENV["WEB_CONCURRENCY"]
  on_worker_shutdown do |index|
    # Delete stale metric files on worker shutdown
    Prometheus::Client.config.data_store.clean_pid(Process.pid)
  end
end
