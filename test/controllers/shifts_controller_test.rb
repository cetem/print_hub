require 'test_helper'

class ShiftsControllerTest < ActionController::TestCase
  setup do
    @shift = shifts(:current_shift)

    sign_in(users(:operator))
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:shifts)
    # assert_select '#unexpected_error', false
    assert_template 'shifts/index'
  end

  test 'should create shift' do
    assert_difference('Shift.count') do
      post :create, params: {
        shift: {
          start: 10.minutes.ago,
          finish: nil,
          description: 'Some shift',
          paid: false
        }
      }
    end

    assert_redirected_to shifts_url
  end

  test 'should show shift' do
    get :show, params: { id: @shift }
    assert_response :success
    # assert_select '#unexpected_error', false
    assert_template 'shifts/show'
  end

  test 'should get edit' do
    get :edit, params: { id: @shift }
    assert_response :success
    # assert_select '#unexpected_error', false
    assert_template 'shifts/edit'
  end

  test 'should update shift' do
    1.minute.ago.to_datetime.tap do |finish|
      assert_no_difference 'Shift.count' do
        put :update, params: { id: @shift, shift: {
          finish: finish,
          description: 'Some shift'
        } }
      end

      assert_redirected_to shifts_url
      assert_equal finish.to_i, @shift.reload.finish.to_i
    end
  end

  test 'should update stale shift' do
    shift = shifts(:open_shift)
    shift.user = users(:operator)
    shift.save!
    session[:has_an_open_shift] = true

    5.hours.ago.to_datetime.tap do |finish|
      assert_no_difference 'Shift.count' do
        put :update, params: { id: shift, shift: {
          finish: finish,
          description: 'Some shift'
        } }
      end

      assert_redirected_to shifts_url
      assert_equal finish.to_i, shift.reload.finish.to_i
      assert !session[:has_an_open_shift]
    end
  end

  test 'should destroy shift' do
    assert_difference('Shift.count', -1) do
      delete :destroy, params: { id: @shift }
    end

    assert_redirected_to shifts_url
  end

  test 'should pay a shift' do
    @shift = shifts(:old_shift)
    assert_difference 'Shift.pay_pending.count', -1 do
      put :update, params: { id: @shift, shift: {
        paid: true
      } }
    end
  end

  test 'should get json pagination' do
    operator = users(:operator) # Operator closed shifts = 3
    operator.update(admin: false)

    get :json_paginate, params: { user_id: operator.id }, format: :json
    assert_response :success

    shifts = ActiveSupport::JSON.decode(@response.body)

    assert_equal 3, shifts.size
    assert shifts.all? { |s| s['user_id'] == operator.id }

    get :json_paginate, params: { user_id: operator.id, limit: 2 }, format: :json
    assert_response :success

    shifts = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, shifts.size
    assert shifts.all? { |s| s['user_id'] == operator.id }

    get :json_paginate, params: { user_id: operator.id, offset: 2 }, format: :json
    assert_response :success

    shifts = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, shifts.size
    assert shifts.all? { |s| s['user_id'] == operator.id }

    get :json_paginate, params: { user_id: operator.id, offset: 1, limit: 3 }, format: :json
    assert_response :success

    shifts = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, shifts.size
    assert shifts.all? { |s| s['user_id'] == operator.id }
  end
end
