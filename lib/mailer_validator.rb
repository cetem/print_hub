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
    return [true, nil]  if Rails.env.test?

    request = Net::HTTP::Get.new MAIL_URI + "?access_key=#{API_KEY}&email=#{email}"
    response = Net::HTTP.start(MAIL_URI.host, MAIL_URI.port, use_ssl: MAIL_URI.scheme == 'https') do |http|
      http.request(request)
    end

    body = (JSON.parse(response.body) rescue {})

    [(response.code == '200') && body['smtp_check'], body['did_you_mean']]
  end
end

