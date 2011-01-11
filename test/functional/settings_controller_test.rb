require 'test_helper'

class SettingsControllerTest < ActionController::TestCase
  setup do
    @user = users(:administrator)
    @setting = settings(:price_per_copy)
  end

  test 'should get index' do
    UserSession.create(@user)
    get :index
    assert_response :success
    assert_not_nil assigns(:settings)
    assert_select '#error_body', false
    assert_template 'settings/index'
  end

  test 'should get show' do
    UserSession.create(@user)
    get :show, :id => @setting.to_param
    assert_response :success
    assert_not_nil assigns(:setting)
    assert_select '#error_body', false
    assert_template 'settings/show'
  end

  test 'should get edit' do
    UserSession.create(@user)
    get :edit, :id => @setting.to_param
    assert_response :success
    assert_not_nil assigns(:setting)
    assert_select '#error_body', false
    assert_template 'settings/edit'
  end

  test 'should update user' do
    UserSession.create(@user)
    put :update, :id => @setting.to_param, :setting => {
      :value => '1234'
    }
    assert_redirected_to settings_path
    assert_equal '1234', @setting.reload.value
  end
end