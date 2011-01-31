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

  test 'should get filtered index' do
    UserSession.create(users(:administrator))
    get :index, :interval => {
      :from => 1.day.ago.to_datetime.to_s(:db),
      :to => 1.day.from_now.to_datetime.to_s(:db)
    }
    assert_response :success
    assert_not_nil assigns(:payments)
    assert_equal 2, assigns(:payments).count
    assert_equal '2010.0', assigns(:payments).sum('amount').to_s
    assert_equal '2007.5', assigns(:payments).sum('paid').to_s
    assert_select '#error_body', false
    assert_template 'payments/index'
  end
end