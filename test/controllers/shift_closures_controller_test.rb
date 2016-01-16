require 'test_helper'

class ShiftClosuresControllerTest < ActionController::TestCase
  setup do
    @shift_closure = shift_closures(:first)
    @operator = users(:operator)

    UserSession.create(@operator)
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
      post :create, shift_closure: {
        cashbox_amount: @shift_closure.cashbox_amount,
        comments:       @shift_closure.comments,
        failed_copies:  @shift_closure.failed_copies,
        finish_at:      @shift_closure.finish_at,
        helper_user_id: @shift_closure.helper_user_id,
        printers_stats: @shift_closure.printers_stats,
        start_at:       @shift_closure.start_at,
      }
    end

    assert_redirected_to shift_closure_path(assigns(:shift_closure))
  end

  test "should show shift_closure" do
    get :show, id: @shift_closure
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @shift_closure
    assert_response :success
  end

  test "should update shift_closure" do
    patch :update, id: @shift_closure, shift_closure: {
      cashbox_amount: @shift_closure.cashbox_amount,
      comments:       @shift_closure.comments,
      failed_copies:  @shift_closure.failed_copies,
      finish_at:      @shift_closure.finish_at,
      helper_user_id: @shift_closure.helper_user_id,
      printers_stats: @shift_closure.printers_stats,
      start_at:       @shift_closure.start_at,
      system_amount:  @shift_closure.system_amount,
      user_id:        @shift_closure.user_id,
    }
    assert_redirected_to shift_closure_path(assigns(:shift_closure))
  end

  test "should destroy shift_closure" do
    assert_difference('ShiftClosure.count', -1) do
      delete :destroy, id: @shift_closure
    end

    assert_redirected_to shift_closures_path
  end
end
