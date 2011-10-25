require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    @controller.send :reset_session
    @controller.send :'response=', @response
    @controller.send :'request=', @request
  end
  
  test 'current customer session' do
    assert_nil @controller.send(:current_customer_session)

    CustomerSession.create(customers(:student))

    assert_not_nil @controller.send(:current_customer_session)
  end

  test 'current customer' do
    assert_nil @controller.send(:current_customer)

    CustomerSession.create(customers(:student))

    assert_not_nil @controller.send(:current_customer)
    assert_equal customers(:student).id, @controller.send(:current_customer).id
  end

  test 'current user session' do
    assert_nil @controller.send(:current_user_session)

    UserSession.create(users(:administrator))

    assert_not_nil @controller.send(:current_user_session)
  end

  test 'current user' do
    assert_nil @controller.send(:current_user)

    UserSession.create(users(:administrator))

    assert_not_nil @controller.send(:current_user)
    assert_equal users(:administrator).id, @controller.send(:current_user).id
  end
  
  test 'require customer' do
    @request.host = "#{CUSTOMER_SUBDOMAIN}.printhub.local"
    
    assert_equal false, @controller.send(:require_customer)
    assert_redirected_to new_customer_session_url
    assert_equal I18n.t('messages.must_be_logged_in'),
      @controller.send(:flash)[:notice]

    CustomerSession.create(customers(:student))
    assert_not_equal false, @controller.send(:require_customer)
  end

  test 'require no customer' do
    @request.host = "#{CUSTOMER_SUBDOMAIN}.printhub.local"
    
    assert @controller.send(:require_no_customer)

    CustomerSession.create(customers(:student))
    assert !@controller.send(:require_no_customer)
    assert_redirected_to catalog_url
    assert_equal I18n.t('messages.must_be_logged_out'),
      @controller.send(:flash)[:notice]
  end

  test 'require user' do
    assert_equal false, @controller.send(:require_user)
    assert_redirected_to new_user_session_url
    assert_equal I18n.t('messages.must_be_logged_in'),
      @controller.send(:flash)[:notice]

    UserSession.create(users(:administrator))
    assert_not_equal false, @controller.send(:require_user)
  end

  test 'require no user' do
    assert @controller.send(:require_no_user)

    UserSession.create(users(:administrator))
    assert !@controller.send(:require_no_user)
    assert_redirected_to prints_url
    assert_equal I18n.t('messages.must_be_logged_out'),
      @controller.send(:flash)[:notice]
  end
  
  test 'require customer or user with user' do
    assert_equal false, @controller.send(:require_customer_or_user)
    assert_redirected_to new_user_session_url
    assert_equal I18n.t('messages.must_be_logged_in'),
      @controller.send(:flash)[:notice]

    UserSession.create(users(:administrator))
    assert_not_equal false, @controller.send(:require_customer_or_user)
  end
  
  test 'require customer or user with customer' do
    @request.host = "#{CUSTOMER_SUBDOMAIN}.printhub.local"
    assert_equal false, @controller.send(:require_customer_or_user)
    assert_redirected_to new_customer_session_url
    assert_equal I18n.t('messages.must_be_logged_in'),
      @controller.send(:flash)[:notice]

    CustomerSession.create(customers(:student))
    assert_not_equal false, @controller.send(:require_customer_or_user)
  end
  
  test 'require no customer or admin with admin' do
    assert_equal false, @controller.send(:require_no_customer_or_admin)
    assert_redirected_to new_user_session_url
    assert_equal I18n.t('messages.must_be_admin'),
      @controller.send(:flash)[:alert]

    UserSession.create(users(:administrator))
    assert_not_equal false, @controller.send(:require_no_customer_or_admin)
  end
  
  test 'require no customer or admin with customer' do
    @request.host = "#{CUSTOMER_SUBDOMAIN}.printhub.local"
    assert @controller.send(:require_no_customer_or_admin)
    
    CustomerSession.create(customers(:student))
    assert !@controller.send(:require_no_customer_or_admin)
    assert_redirected_to catalog_url
    assert_equal I18n.t('messages.must_be_logged_out'),
      @controller.send(:flash)[:notice]
  end
  
  test 'require no customer or admin with user' do
    UserSession.create(users(:operator))
    assert !@controller.send(:require_no_customer_or_admin)
    assert_redirected_to prints_url
    assert_equal I18n.t('messages.must_be_admin'),
      @controller.send(:flash)[:alert]
  end

  test 'require admin user with admin user' do
    UserSession.create(users(:administrator))
    assert_not_equal false, @controller.send(:require_admin_user)
  end

  test 'require admin with a non admin user' do
    UserSession.create(users(:operator))
    assert_equal false, @controller.send(:require_admin_user)
    assert_redirected_to prints_url
    assert_equal I18n.t('messages.must_be_admin'),
      @controller.send(:flash)[:alert]
  end

  test 'require admin user without user' do
    assert_equal false, @controller.send(:require_admin_user)
    assert_redirected_to new_user_session_url
    assert_equal I18n.t('messages.must_be_admin'),
      @controller.send(:flash)[:alert]
  end

  test 'store location' do
    assert_nil @controller.send(:session)[:return_to]
    assert @controller.send(:store_location)
    assert_not_nil @controller.send(:session)[:return_to]
  end

  test 'redirect to back of default' do
    @controller.send(:redirect_back_or_default, new_user_session_url)

    assert_redirected_to new_user_session_url
  end

  test 'make date range' do
    from_datetime = Time.now.at_beginning_of_day
    to_datetime = Time.now

    assert_equal [from_datetime.to_s(:db), to_datetime.to_s(:db)],
      @controller.send(:make_datetime_range).map { |d| d.to_s(:db) }

    # Fechas inválidas
    assert_equal [from_datetime.to_s(:db), to_datetime.to_s(:db)],
      @controller.send(
        :make_datetime_range,
        {from: 'wrong date', to: 'another wrong date'}
      ).map { |d| d.to_s(:db) }

    from_datetime = Time.parse '2011-10-09 10:00'
    to_datetime = Time.parse '2000-10-09 11:50'

    generated_range = @controller.send(:make_datetime_range, {
        from: '2011-10-09 10:00', to: '2000-10-09 11:50'
      }).map { |d| d.to_s(:db) }

    # Fechas válidas con el orden invertido
    assert_equal [to_datetime.to_s(:db), from_datetime.to_s(:db)],
      generated_range
  end
end