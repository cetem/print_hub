require 'test_helper'

class UserSessionsControllerTest < ActionController::TestCase
  setup do
    @operator = users(:operator)
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_not_nil assigns(:user_session)
    # assert_select '#unexpected_error', false
    assert_template 'user_sessions/new'
  end

  test 'should create user session' do
    @operator.close_pending_shifts!

    assert_difference '@operator.shifts.count' do
      post :create, params: {
        user_session: {
          username: @operator.username,
          password: "#{@operator.username}123"
        }
      }
    end

    assert user_session = UserSession.find
    assert_equal @operator, user_session.user
    assert_redirected_to prints_url
  end

  test 'should create user session with pending shift' do
    @operator.close_pending_shifts!
    @operator.start_shift!

    assert !session[:has_an_open_shift]

    assert_no_difference '@operator.shifts.count' do
      post :create, params: {
        user_session: {
          username: @operator.username,
          password: "#{@operator.username}123"
        }
      }
    end

    assert !session[:has_an_open_shift]

    assert user_session = UserSession.find
    assert_equal @operator, user_session.user
    assert_redirected_to prints_url
  end

  test 'should create user session with stale shift' do
    @operator.close_pending_shifts!

    @shift = Shift.create!(user_id: @operator.id, start: 9.hours.ago)

    assert !session[:has_an_open_shift]
    assert_no_difference '@operator.shifts.count' do
      post :create, params: {
        user_session: {
          username: @operator.username,
          password: "#{@operator.username}123"
        }
      }
    end

    assert user_session = UserSession.find

    assert_equal @operator, user_session.user
    assert session[:has_an_open_shift]
    assert_redirected_to edit_shift_url(@shift)
  end

  test 'should not create a user session' do
    assert_no_difference '@operator.shifts.count' do
      post :create, params: {
        user_session: {
          username: @operator.username,
          password: 'wrong'
        }
      }
    end

    assert_nil UserSession.find
    assert_response :success
    assert_not_nil assigns(:user_session)
    # assert_select '#unexpected_error', false
    assert_template 'user_sessions/new'
  end

  test 'should not create a user session with a disabled user' do
    @operator.update(enable: false)

    assert_no_difference '@operator.shifts.count' do
      post :create, params: {
        user_session: {
          username: @operator.username,
          password: "#{@operator.username}123"
        }
      }
    end

    assert_nil UserSession.find
    assert_response :success
    assert_not_nil assigns(:user_session)
    # assert_select '#unexpected_error', false
    assert_template 'user_sessions/new'
  end

  test 'should destroy user session and close shift' do
    @operator.close_pending_shifts!

    assert_difference '@operator.shifts.count' do
      sign_in(@operator)
    end

    assert_not_nil UserSession.find
    assert_equal 1, @operator.shifts.pending.size

    delete :destroy, params: { close_shift: true }

    assert_equal 0, @operator.shifts.pending.reload.size

    assert_nil UserSession.find
    assert_redirected_to new_user_session_url
  end

  test 'should destroy user session and close shift as operator' do
    @operator.close_pending_shifts!

    assert_difference '@operator.shifts.count' do
      sign_in(@operator)
    end

    assert_not_nil UserSession.find
    assert_equal 1, @operator.shifts.pending.size
    assert @operator.last_open_shift.as_admin

    delete :destroy, params: { close_shift: true, as_operator: true }

    assert_equal false, @operator.shifts.order(id: :desc).first.reload.as_admin
    assert_equal 0, @operator.shifts.pending.reload.size

    assert_nil UserSession.find
    assert_redirected_to new_user_session_url
  end

  test 'should exit whitout close the shift' do
    @operator.close_pending_shifts!

    sign_in(@operator)

    assert_equal 1, @operator.shifts.pending.size

    delete :destroy

    assert_equal 1, @operator.reload.shifts.pending.size
    assert_nil @operator.shifts.pending.last.finish

    assert_nil UserSession.find
    assert_redirected_to new_user_session_url
  end
end
