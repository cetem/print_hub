class Notifications < ActionMailer::Base
  default from: "\"#{t(:app_name)}\" <#{NOTIFICATIONS_EMAIL}>",
    charset: 'UTF-8',
    content_type: 'text/html',
    date: proc { Time.now }

  def signup(customer)
    mail to: customer.email
  end

  def forgot_password(customer)
    mail to: customer.email
  end
end
