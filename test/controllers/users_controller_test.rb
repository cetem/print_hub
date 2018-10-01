require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @operator = users(:operator)

    sign_in(@operator)

    prepare_avatar_files
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
    # assert_select '#unexpected_error', false
    assert_template 'users/index'
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_not_nil assigns(:user)
    # assert_select '#unexpected_error', false
    assert_template 'users/new'
  end

  test 'should create user' do
    assert_difference ['User.count', 'PaperTrail::Version.count'] do
      post :create, params: {
        user: {
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
      }
    end

    assert_redirected_to users_path
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal @operator.id, PaperTrail::Version.last.whodunnit
  end

  test 'should show user' do
    get :show, params: { id: @operator.to_param }
    assert_response :success
    assert_not_nil assigns(:user)
    # assert_select '#unexpected_error', false
    assert_template 'users/show'
  end

  test 'should get edit' do
    get :edit, params: { id: @operator.to_param }
    assert_response :success
    assert_not_nil assigns(:user)
    # assert_select '#unexpected_error', false
    assert_template 'users/edit'
  end

  test 'should update user' do
    put :update, params: { id: @operator.to_param, user: {
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
    } }
    assert_redirected_to users_path
    assert_equal 'Updated name', @operator.reload.name
  end

  test 'should get autocomplete user list' do
    get :autocomplete_for_user_name, params: { q: 'operator' }, format: :json
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size
    assert users.all? { |u| (u['label'] + u['informal']).match /operator/i }

    get :autocomplete_for_user_name, params: { q: 'invalid_operator' }, format: :json
    assert_response :success

    customers = ActiveSupport::JSON.decode(@response.body)

    assert customers.empty?

    get :autocomplete_for_user_name, params: { q: 'disabled operator' }, format: :json
    assert_response :success

    customers = ActiveSupport::JSON.decode(@response.body)

    assert customers.empty?
  end

  test 'should pay user shifts between dates' do
    user = users(:operator)
    start = 3.weeks.ago.to_date
    finish = Time.zone.today
    pending_shifts = user.shifts.pay_pending

    assert pending_shifts.size > 0

    assert_difference 'pending_shifts.count', -pending_shifts.count do
      put :pay_shifts_between, params: {
                                 id: user.to_param,
                                 start: start.to_s(:db),
                                 finish: finish.to_s(:db)
                               },
                               format: :json
      assert_response :success
    end
  end

  test 'should get current workers' do
    get :current_workers, format: :json
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size
  end

  test 'should get pay pending for user between dates' do
    Shift.all.update_all(paid: false)
    finished_shifts = Shift.finished.count

    from = 2.month.ago.to_date
    to = 1.day.from_now.to_date
    users_shifts = User.pay_pending_shifts_for_active_users_between(from, to).first

    get :pay_pending_shifts_for_active_users_between, params: {
                                                        start: from.to_s(:db),
                                                        finish: to.to_s(:db)
                                                      },
                                                      format: :json

    assert_response :success

    response_users_shifts = ActiveSupport::JSON.decode(@response.body).first.deep_symbolize_keys
    response_shifts = response_users_shifts[:shifts]
    response_shifts_count = (
      response_shifts[:operator][:count] +
      response_shifts[:admin][:count]
    )

    assert_equal users_shifts, response_users_shifts
    assert finished_shifts > 0
    assert_equal finished_shifts, response_shifts_count
  end
end
