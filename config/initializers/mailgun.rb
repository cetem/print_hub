if (key = Rails.application.secrets.mailgun_api_key)
  $mailgun = Mailgunner::Client.new(api_key: key)
end
