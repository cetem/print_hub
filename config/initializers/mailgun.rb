unless Rails.env.test?
  api_key = APP_CONFIG['mailgun_api_key']
  $mailgun = Mailgunner::Client.new(api_key: api_key) if api_key
end
