app_path = File.expand_path(File.dirname(__FILE__) + "/..")
Dir["#{app_path}/config/initializers/*.rb"].each { |f| require f }
