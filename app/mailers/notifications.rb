class Notifications < ActionMailer::Base
  layout 'notifications_mailer'
  default from: "\"#{I18n.t('app_name')}\" <#{APP_CONFIG['smtp']['user_name']}>",
    charset: 'UTF-8',
    date: -> { Time.now }

  def signup(customer)
    @customer = customer
    
    mail to: customer.email
  end

  def forgot_password(customer)
    @customer = customer
    
    mail to: customer.email
  end
end
