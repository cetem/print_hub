require 'test_helper'

class PaymentsControllerTest < ActionController::TestCase
  def setup
    sign_in(users(:operator))
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:payments)
    # # assert_select '#unexpected_error', false
    # assert_template 'payments/index'
  end

  test 'should get filtered index' do
    get :index, params: {
      interval: {
        from: 1.day.ago.to_datetime.to_s(:db),
        to: 1.day.from_now.to_datetime.to_s(:db)
      }
    }
    assert_response :success
    assert_not_nil assigns(:payments)
    assert_equal 4, assigns(:payments).count

    assert_equal '88.17', assigns(:payments).to_a.sum(&:amount).to_s
    assert_equal '45.0', assigns(:payments).to_a.sum(&:paid).to_s
    assert_equal '1001.5', assigns(:deposits).to_a.sum(&:amount).to_s
    # # assert_select '#unexpected_error', false
    # assert_template 'payments/index'
  end

  test 'should get filtered index with 0 amount' do
    get :index, params: {
      interval: {
        from: 2.years.ago.to_datetime.to_s(:db),
        to: 1.year.ago.to_datetime.to_s(:db)
      }
    }
    assert_response :success
    assert_not_nil assigns(:payments)
    assert_equal 0, assigns(:payments).count
    assert_equal '0.0', assigns(:payments).to_a.sum(&:amount).to_f.to_s
    assert_equal '0.0', assigns(:payments).to_a.sum(&:paid).to_f.to_s
    # # assert_select '#unexpected_error', false
    # assert_template 'payments/index'
  end
end
