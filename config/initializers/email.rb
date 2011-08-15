config = APP_CONFIG['smtp'].inject({}){ |memo, (k,v)| memo[k.to_sym] = v; memo }

PrintHubApp::Application.config.action_mailer.default_url_options = {
  :host => APP_CONFIG['public_host']
}

PrintHubApp::Application.config.action_mailer.smtp_settings = config
