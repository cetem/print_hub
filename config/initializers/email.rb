Rails.application.routes.default_url_options ||= {}
Rails.application.routes.default_url_options[:host] = APP_CONFIG['public_host']
Rails.application.configure do
  config.action_mailer.default_url_options ||= {}
  config.action_mailer.delivery_method = Rails.env.test? ? :test : :smtp
  config.action_mailer.default_url_options[:host] = APP_CONFIG['public_host']
  config.action_mailer.smtp_settings = APP_CONFIG['smtp'].symbolize_keys
end
