require 'test_helper'

class NotificationsTest < ActionMailer::TestCase
  test 'signup' do
    customer = customers(:student)
    mail = Notifications.signup(customer.email)

    assert_equal I18n.t('notifications.signup.subject'), mail.subject
    assert_equal [customer.email], mail.to
    assert_equal [APP_CONFIG['smtp']['user_name']], mail.from
    body = mail.body.encoded
    assert_match 'Bienvenido', body
    assert_match 'lista para usarse', body

    assert_difference 'ActionMailer::Base.deliveries.size' do
      mail.deliver_now!
    end
  end

  test 'forgot password' do
    customer = customers(:student)
    mail = Notifications.forgot_password(customer.email)

    assert_equal I18n.t('notifications.forgot_password.subject'), mail.subject
    assert_equal [customer.email], mail.to
    assert_equal [APP_CONFIG['smtp']['user_name']], mail.from
    assert_match 'Cambio', mail.body.encoded

    assert_difference 'ActionMailer::Base.deliveries.size' do
      mail.deliver_now!
    end
  end
end
