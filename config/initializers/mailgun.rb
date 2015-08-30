if (key = Rails.application.secrets.mailgun_api_key) && !Rails.env.test?
  $mailgun = Mailgunner::Client.new(api_key: key)
end
