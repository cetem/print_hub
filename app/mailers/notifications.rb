class Notifications < ActionMailer::Base
  layout 'notifications_mailer'
  default from: "\"#{I18n.t('app_name')}\" <#{APP_CONFIG['smtp']['user_name']}>",
          charset: 'UTF-8'

  def signup(customer_email)
    @customer = Customer.find_by(email: customer_email)

    mail to: @customer.email, date: -> { Time.zone.now }
  end

  def reactivation(customer_email)
    @customer = Customer.find_by(email: customer_email)

    mail to: @customer.email, date: -> { Time.zone.now }
  end

  def forgot_password(customer_email)
    @customer = Customer.find_by(email: customer_email)

    mail to: @customer.email, date: -> { Time.zone.now }
  end
end
