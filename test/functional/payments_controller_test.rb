require 'test_helper'

class PaymentsControllerTest < ActionController::TestCase
  test 'should get index' do
    UserSession.create(users(:administrator))
    get :index
    assert_response :success
    assert_not_nil assigns(:payments)
    assert_select '#error_body', false
    assert_template 'payments/index'
  end
end