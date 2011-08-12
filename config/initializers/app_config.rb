config_path = File.join(Rails.root, 'config', 'app_config.yml')

if File.exists?(config_path)
  APP_CONFIG = YAML.load File.read(config_path)
else
  raise "You must have a configuration file in #{config_path}, see config/app_config.example.yml"
end