class Notifications < ActionMailer::Base
  layout 'notifications_mailer'
  default from: "\"#{I18n.t('app_name')}\" <#{APP_CONFIG['smtp']['user_name']}>",
    charset: 'UTF-8'

  def signup(customer)
    @customer = customer

    mail to: customer.email, date: -> { Time.now }
  end

  def reactivation(customer)
    @customer = customer

    mail to: customer.email, date: -> { Time.now }
  end

  def forgot_password(customer)
    @customer = customer

    mail to: customer.email, date: -> { Time.now }
  end
end
