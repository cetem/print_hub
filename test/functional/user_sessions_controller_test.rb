require 'test_helper'

class UserSessionsControllerTest < ActionController::TestCase
  setup do
    @user = users(:administrator)
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_not_nil assigns(:user_session)
    assert_select '#error_body', false
    assert_template 'user_sessions/new'
  end

  test 'should create user session' do
    post :create, :user_session => {
      :username => @user.username,
      :password => 'admin123'
    }

    assert user_session = UserSession.find
    assert_equal @user, user_session.user
    assert_redirected_to prints_url
  end

  test 'should destroy user session' do
    delete :destroy

    assert_nil UserSession.find
    assert_redirected_to new_user_session_url
  end
end