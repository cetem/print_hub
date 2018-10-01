require 'test_helper'

class ShiftClosuresControllerTest < ActionController::TestCase
  setup do
    @shift_closure = shift_closures(:first)
    @operator = users(:operator)

    sign_in(@operator)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:shift_closures)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create shift_closure" do
    assert_difference('ShiftClosure.count') do
      post :create, params: { shift_closure: @shift_closure.dup.attributes }
    end

    assert_redirected_to shift_closure_path(assigns(:shift_closure))
  end

  test "should show shift_closure" do
    get :show, params: { id: @shift_closure }
    assert_response :success
  end

  test "should get edit" do
    @shift_closure.update_column(:finish_at, nil)

    get :edit, params: { id: @shift_closure }
    assert_response :success
  end

  test "should update shift_closure" do
    @shift_closure.update_column(:finish_at, nil)

    patch :update, params: { id: @shift_closure, shift_closure: {
      cashbox_amount: @shift_closure.cashbox_amount,
      comments:       @shift_closure.comments,
      failed_copies:  @shift_closure.failed_copies,
      helper_user_id: @shift_closure.helper_user_id,
      printers_stats: @shift_closure.printers_stats,
      start_at:       3.days.ago.to_s(:db),
      system_amount:  @shift_closure.system_amount,
      user_id:        @shift_closure.user_id,
    } }
    assert_redirected_to shift_closure_path(assigns(:shift_closure))
  end

  test "should destroy shift_closure" do
    assert_difference('ShiftClosure.count', -1) do
      delete :destroy, params: { id: @shift_closure }
    end

    assert_redirected_to shift_closures_path
  end
end
