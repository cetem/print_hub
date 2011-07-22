require 'test_helper'

class CustomerSessionsControllerTest < ActionController::TestCase
  setup do
    @customer = customers(:student)
    @request.host = 'facultad.printhub.local'
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_not_nil assigns(:customer_session)
    assert_select '#error_body', false
    assert_template 'customer_sessions/new'
  end

  test 'should create user session' do
    post :create, :customer_session => {
      :email => @customer.email,
      :password => 'student123'
    }

    assert customer_session = CustomerSession.find
    assert_equal @customer, customer_session.record
    assert_redirected_to orders_url
  end

  test 'should not create a customer session' do
    post :create, :customer_session => {
      :email => @customer.email,
      :password => 'wrong'
    }

    assert_nil CustomerSession.find
    assert_response :success
    assert_not_nil assigns(:customer_session)
    assert_select '#error_body', false
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