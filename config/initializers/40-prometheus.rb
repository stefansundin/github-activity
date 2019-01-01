# The app is currently run with multiple processes, which means that the /metrics endpoint is not consistent.. That's fine for now, at least with this one metric.

prometheus = Prometheus::Client.registry

$metrics = {
  ratelimit_remaining: prometheus.gauge(:ratelimit_remaining, "Remaining GitHub ratelimit."),
}
