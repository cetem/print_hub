module MailerValidator
  MAIL_URI = URI.parse('https://apilayer.net/api/check')
  API_KEY = Rails.application.secrets[:mailboxlayer_api_key]

  # response example
  # { "email"=>"someuser@gmail.com",
  #   "did_you_mean"=>"",
  #   "user"=>"someuser",
  #   "domain"=>"gmail.com",
  #   "format_valid"=>true,
  #   "mx_found"=>true,
  #   "smtp_check"=>true,
  #   "catch_all"=>nil,
  #   "role"=>false,
  #   "disposable"=>false,
  #   "free"=>true,
  #   "score"=>0.8}
  def self.check(email)
    return [false, nil] if email.blank?
    return [true, nil]  if Rails.env.test? || API_KEY.blank?

    api_key = if API_KEY.is_a?(Array)
                API_KEY.sample
              else
                API_KEY
              end

    request = Net::HTTP::Get.new MAIL_URI + "?access_key=#{api_key}&email=#{email}"
    response = Net::HTTP.start(MAIL_URI.host, MAIL_URI.port, use_ssl: MAIL_URI.scheme == 'https') do |http|
      http.request(request)
    end

    body = (JSON.parse(response.body) rescue {})

    Rails.logger.info('MailerValidator: ')
    Rails.logger.info(body)

    if body['success'] == false
      Bugsnag.notify(
        RuntimeError.new('Error en MailerValidator'),
        user: {
          body: body
        }
      )

      return true
    end

    [(response.code == '200') && body['format_valid'] && body['mx_found'], body['did_you_mean']]
  end
end

