require 'test_helper'

class ShiftsControllerTest < ActionController::TestCase
  setup do
    @shift = shifts(:current_shift)

    UserSession.create(users(:operator))
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:shifts)
    assert_select '#unexpected_error', false
    assert_template 'shifts/index'
  end

  test 'should create shift' do
    assert_difference('Shift.count') do
      post :create, shift: {
        start: 10.minutes.ago,
        finish: nil,
        description: 'Some shift',
        paid: false
      }
    end

    assert_redirected_to shifts_url
  end

  test 'should show shift' do
    get :show, id: @shift
    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'shifts/show'
  end

  test 'should get edit' do
    get :edit, id: @shift
    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'shifts/edit'
  end

  test 'should update shift' do
    1.minute.ago.to_datetime.tap do |finish|
      assert_no_difference 'Shift.count' do
        put :update, id: @shift, shift: {
          finish: finish,
          description: 'Some shift'
        }
      end

      assert_redirected_to shifts_url
      assert_equal finish.to_i, @shift.reload.finish.to_i
    end
  end

  test 'should update stale shift' do
    shift = shifts(:open_shift)
    session[:has_an_open_shift] = true

    5.hours.ago.to_datetime.tap do |finish|
      assert_no_difference 'Shift.count' do
        put :update, id: shift, shift: {
          finish: finish,
          description: 'Some shift'
        }
      end

      assert_redirected_to shifts_url
      assert_equal finish.to_i, shift.reload.finish.to_i
      assert !session[:has_an_open_shift]
    end
  end

  test 'should destroy shift' do
    assert_difference('Shift.count', -1) do
      delete :destroy, id: @shift
    end

    assert_redirected_to shifts_url
  end

  test 'should pay a shift' do
    @shift = shifts(:old_shift)
    assert_difference 'Shift.pay_pending.count', -1 do
      put :update, id: @shift, shift: {
        paid: true
      }
    end
  end

  test 'should get json pagination' do
    operator = users(:operator) # Operator closed shifts = 3
    operator.update(admin: false)

    get :json_paginate, format: :json, user_id: operator.id
    assert_response :success

    shifts = ActiveSupport::JSON.decode(@response.body)

    assert_equal 3, shifts.size
    assert shifts.all? { |s| s['user_id'] == operator.id }

    get :json_paginate, format: :json, user_id: operator.id, limit: 2
    assert_response :success

    shifts = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, shifts.size
    assert shifts.all? { |s| s['user_id'] == operator.id }

    get :json_paginate, format: :json, user_id: operator.id, offset: 2
    assert_response :success

    shifts = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, shifts.size
    assert shifts.all? { |s| s['user_id'] == operator.id }

    get :json_paginate, format: :json, user_id: operator.id, offset: 1,
      limit: 3
    assert_response :success

    shifts = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, shifts.size
    assert shifts.all? { |s| s['user_id'] == operator.id }
  end
end
