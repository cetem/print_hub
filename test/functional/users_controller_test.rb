require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @user = users(:administrator)
    
    prepare_avatar_files
  end

  test 'should get index' do
    UserSession.create(@user)
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
    assert_select '#unexpected_error', false
    assert_template 'users/index'
  end

  test 'should get new' do
    UserSession.create(@user)
    get :new
    assert_response :success
    assert_not_nil assigns(:user)
    assert_select '#unexpected_error', false
    assert_template 'users/new'
  end

  test 'should create user' do
    UserSession.create(@user)
    assert_difference ['User.count', 'Version.count'] do
      post :create, user: {
        name: 'New name',
        last_name: 'New last name',
        email: 'new_user@printhub.com',
        default_printer: '',
        lines_per_page: '12',
        language: LANGUAGES.first.to_s,
        username: 'new_user',
        password: 'new_password',
        password_confirmation: 'new_password',
        admin: '1',
        enable: '1',
        avatar: fixture_file_upload('/files/test.gif', 'image/gif')
      }
    end

    assert_redirected_to users_path
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal users(:administrator).id, Version.last.whodunnit
  end

  test 'should show user' do
    UserSession.create(@user)
    get :show, id: @user.to_param
    assert_response :success
    assert_not_nil assigns(:user)
    assert_select '#unexpected_error', false
    assert_template 'users/show'
  end

  test 'should get edit' do
    UserSession.create(@user)
    get :edit, id: @user.to_param
    assert_response :success
    assert_not_nil assigns(:user)
    assert_select '#unexpected_error', false
    assert_template 'users/edit'
  end

  test 'should update user' do
    UserSession.create(@user)
    put :update, id: @user.to_param, user: {
      name: 'Updated name',
      last_name: 'Updated last name',
      email: 'updated_user@printhub.com',
      default_printer: '',
      lines_per_page: '12',
      language: LANGUAGES.first.to_s,
      password: 'updated_password',
      password_confirmation: 'updated_password',
      admin: '1',
      enable: '1'
    }
    assert_redirected_to users_path
    assert_equal 'Updated name', @user.reload.name
  end
  
  test 'should not download avatar' do
    UserSession.create(users(:administrator))
    FileUtils.rm @user.avatar.path if File.exists?(@user.avatar.path)

    assert !File.exists?(@user.avatar.path)
    get :avatar, id: @user.to_param, style: :original
    assert_redirected_to action: :index
    assert_equal I18n.t('view.users.non_existent_avatar'), flash.notice
  end

  test 'should download avatar' do
    UserSession.create(users(:administrator))
    get :avatar, id: @user.to_param, style: :original
    assert_response :success
    assert_equal(
      File.open(@user.reload.avatar.path, encoding: 'ASCII-8BIT').read,
      @response.body
    )
  end
  
  test 'should get autocomplete user list' do
    UserSession.create(@user)
    get :autocomplete_for_user_name, format: :json, q: 'admin'
    assert_response :success
    
    users = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal 1, users.size
    assert users.all? { |u| (u['label'] + u['informal']).match /admin/i }

    get :autocomplete_for_user_name, format: :json, q: 'invalid_operator'
    assert_response :success
    
    customers = ActiveSupport::JSON.decode(@response.body)
    
    assert customers.empty?
  end

  test 'should pay user shifts between dates' do
    UserSession.create(@user)
    user = users(:operator)
    from = 3.weeks.ago.to_date
    to = Time.zone.today
    pending_shifts = user.shifts.pay_pending
    
    assert pending_shifts.size > 0

    assert_difference 'pending_shifts.count', -pending_shifts.count do
      put :pay_shifts_between, format: :json,
        id: user.to_param, start: from, finish: to
      assert_response :success
    end
  end
end
