config_path = File.join(Rails.root, 'config', 'app_config.yml')

if File.exist?(config_path)
  APP_CONFIG = YAML.load(File.read(config_path))
                   .deep_symbolize_keys
                   .with_indifferent_access
else
  fail "You must have a configuration file in #{config_path}, see config/app_config.example.yml"
end

SECRETS = Rails.application.secrets
          .deep_symbolize_keys
          .with_indifferent_access

# Devise regex
EMAIL_REGEX = /\A[\w+\-\.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
