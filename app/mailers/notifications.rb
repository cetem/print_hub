class Notifications < ActionMailer::Base
  layout 'notifications_mailer'
  default from: "\"#{I18n.t('app_name')}\" <#{APP_CONFIG['smtp']['user_name']}>",
          charset: 'UTF-8'

  def signup(customer_id)
    @customer = Customer.find(customer_id)

    mail to: @customer.email, date: -> { Time.zone.now }
  end

  def reactivation(customer_id)
    @customer = Customer.find(customer_id)

    mail to: @customer.email, date: -> { Time.zone.now }
  end

  def forgot_password(customer_id)
    @customer = Customer.find(customer_id)

    mail to: @customer.email, date: -> { Time.zone.now }
  end
end
