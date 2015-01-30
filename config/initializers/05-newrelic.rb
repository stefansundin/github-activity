if ENV["NEWRELIC_KEY"]
  require "newrelic_rpm"

  NewRelic::Agent.after_fork(force_reconnect: true)
end
