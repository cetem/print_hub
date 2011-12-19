require 'test_helper'

class NotificationsTest < ActionMailer::TestCase
  test 'signup' do
    customer = Customer.find(customers(:student).id)
    mail = Notifications.signup(customer)
    assert_equal I18n.t('notifications.signup.subject'), mail.subject
    assert_equal [customer.email], mail.to
    assert_equal [APP_CONFIG['smtp']['user_name']], mail.from
    assert_match 'Bienvenido', mail.body.encoded
    assert_match 'lista para usarse', mail.body.encoded
    
    assert_difference 'ActionMailer::Base.deliveries.size' do
      mail.deliver
    end
  end
  
  test 'signup with disabled customer' do
    customer = Customer.unscoped.find(
      ActiveRecord::Fixtures.identify(:disabled_student)
    )
    mail = Notifications.signup(customer)
    assert_equal I18n.t('notifications.signup.subject'), mail.subject
    assert_equal [customer.email], mail.to
    assert_equal [APP_CONFIG['smtp']['user_name']], mail.from
    assert_match 'Bienvenido', mail.body.encoded
    assert_match 'activar', mail.body.encoded
    
    assert_difference 'ActionMailer::Base.deliveries.size' do
      mail.deliver
    end
  end
  
  test 'reactivation' do
    customer = Customer.unscoped.find(
      ActiveRecord::Fixtures.identify(:disabled_student)
    )
    mail = Notifications.reactivation(customer)
    assert_equal I18n.t('notifications.reactivation.subject'), mail.subject
    assert_equal [customer.email], mail.to
    assert_equal [APP_CONFIG['smtp']['user_name']], mail.from
    assert_match 'Cambio de correo', mail.body.encoded
    
    assert_difference 'ActionMailer::Base.deliveries.size' do
      mail.deliver
    end
  end

  test 'forgot password' do
    customer = Customer.find(customers(:student).id)
    mail = Notifications.forgot_password(customer)
    assert_equal I18n.t('notifications.forgot_password.subject'), mail.subject
    assert_equal [customer.email], mail.to
    assert_equal [APP_CONFIG['smtp']['user_name']], mail.from
    assert_match 'Cambio', mail.body.encoded
    
    assert_difference 'ActionMailer::Base.deliveries.size' do
      mail.deliver
    end
  end
end