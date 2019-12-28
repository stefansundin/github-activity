# frozen_string_literal: true

# Use DirectFileStore if we run multiple processes
store_settings = {}
if ENV["WEB_CONCURRENCY"]
  require "prometheus/client/data_stores/direct_file_store"
  app_path = File.expand_path("../../..", __FILE__)
  Prometheus::Client.config.data_store = Prometheus::Client::DataStores::DirectFileStore.new(dir: "#{app_path}/tmp/prometheus/", clean_dir: true)
  store_settings[:aggregation] = :most_recent
end

prometheus = Prometheus::Client.registry

$metrics = {
  ratelimit_remaining: prometheus.gauge(:ratelimit_remaining, store_settings: store_settings, docstring: "Remaining GitHub ratelimit."),
}
