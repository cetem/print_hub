require 'test_helper'

class CustomerSessionsControllerTest < ActionController::TestCase
  setup do
    @customer = customers(:student)
    @request.host = 'fotocopia.printhub.local'
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_not_nil assigns(:customer_session)
    # assert_select '#unexpected_error', false
    assert_template 'customer_sessions/new'
  end

  test 'should update old password and create customer session' do
    old_password = Authlogic::CryptoProviders::Sha512.encrypt('student123' + @customer.password_salt)
    assert_not_equal old_password, @customer.crypted_password

    @customer.update_column(:crypted_password, old_password)

    post :create, params: {
      customer_session: {
        email:    @customer.email,
        password: 'student123'
      }
    }

    assert customer_session = CustomerSession.find
    assert_equal @customer, customer_session.record
    assert_not_equal old_password, @customer.reload.crypted_password
  end

  test 'should create customer session' do
    post :create, params: {
      customer_session: {
        email: @customer.email,
        password: 'student123'
      }
    }

    assert customer_session = CustomerSession.find
    assert_equal @customer, customer_session.record
    assert_redirected_to catalog_url
  end

  test 'should not create a customer session' do
    post :create, params: {
      customer_session: {
        email: @customer.email,
        password: 'wrong'
      }
    }

    assert_nil CustomerSession.find
    assert_response :success
    assert_not_nil assigns(:customer_session)
    # assert_select '#unexpected_error', false
    assert_template 'customer_sessions/new'
  end

  test 'should destroy customer session' do
    CustomerSession.create(@customer)

    assert_not_nil CustomerSession.find

    delete :destroy

    assert_nil CustomerSession.find
    assert_redirected_to new_customer_session_url
  end
end
