require 'test_helper'

class BonusesControllerTest < ActionController::TestCase
  test 'should get index' do
    UserSession.create(users(:administrator))
    
    get :index
    assert_response :success
    assert_not_nil assigns(:bonuses)
    assert_equal Bonus.count, assigns(:bonuses).size
    assert_select '#error_body', false
    assert_template 'bonuses/index'
  end
  
  test 'should get customer index' do
    UserSession.create(users(:administrator))
    customer = customers(:student)
    
    get :index, :customer_id => customer.to_param
    assert_response :success
    assert_not_nil assigns(:bonuses)
    assert_equal customer.bonuses.count, assigns(:bonuses).size
    assert assigns(:bonuses).all? { |b| b.customer_id == customer.id }
    assert_select '#error_body', false
    assert_template 'bonuses/index'
  end
end