require 'test_helper'

class UserSessionsControllerTest < ActionController::TestCase
  setup do
    @operator = users(:operator)
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_not_nil assigns(:user_session)
    assert_select '#unexpected_error', false
    assert_template 'user_sessions/new'
  end

  test 'should create user session' do
    @operator.close_pending_shifts!

    assert_difference '@operator.shifts.count' do
      post :create, user_session: {
        username: @operator.username, 
        password: "#{@operator.username}123"
      }
    end

    assert user_session = UserSession.find
    assert_equal @operator, user_session.user
    assert_redirected_to prints_url
  end
  
  test 'should create user session with pending shift' do
    @operator.start_shift!

    assert !session[:has_an_open_shift]
    
    assert_no_difference '@operator.shifts.count' do
      post :create, user_session: {
        username: @operator.username, 
        password: "#{@operator.username}123"
      }
    end

    assert !session[:has_an_open_shift]

    assert user_session = UserSession.find
    assert_equal @operator, user_session.user
    assert_redirected_to prints_url
  end
  
  test 'should create user session with stale shift' do
   
    assert !session[:has_an_open_shift]
    
    assert_no_difference '@operator.shifts.count' do
      post :create, user_session: {
        username: @operator.username,
        password: "#{@operator.username}123"
      }
    end

    assert user_session = UserSession.find
    assert_equal @operator, user_session.user
    assert session[:has_an_open_shift]
    assert_redirected_to edit_shift_url(shifts(:open_shift))
  end
  
  test 'should not create a user session' do
    assert_no_difference '@operator.shifts.count' do
      post :create, user_session: {
        username: @operator.username,
        password: 'wrong'
      }
    end

    assert_nil UserSession.find
    assert_response :success
    assert_not_nil assigns(:user_session)
    assert_select '#unexpected_error', false
    assert_template 'user_sessions/new'
  end

  test 'should not create a user session with a disabled user' do
    disabled_user = users(:operator)
    disabled_user.update_attributes(enable: false)
    assert_no_difference 'disabled_user.shifts.count' do
      post :create, user_session: {
        username: disabled_user.username, 
        password: "#{@operator.username}123"
      }
    end

    assert_nil UserSession.find
    assert_response :success
    assert_not_nil assigns(:user_session)
    assert_select '#unexpected_error', false
    assert_template 'user_sessions/new'
  end

  test 'should destroy user session and close shift' do
    @operator.close_pending_shifts!
  
    assert_difference '@operator.shifts.count' do
      UserSession.create(@operator)
    end

    assert_not_nil UserSession.find
    
    assert_equal 1, @operator.shifts.pending.size
    
    delete :destroy, close_shift: true
    
    assert_equal 0, @operator.shifts.pending.reload.size

    assert_nil UserSession.find
    assert_redirected_to new_user_session_url
  end
  
  test 'should exit whitout close the shift' do
    UserSession.create(@operator)
    
    assert_equal 1, @operator.shifts.pending.size
    
    delete :destroy
    
    assert_equal 1, @operator.reload.shifts.pending.size
    assert_nil @operator.shifts.pending.last.finish
    
    assert_nil UserSession.find
    assert_redirected_to new_user_session_url
  end
end
