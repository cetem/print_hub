require 'test_helper'

class PrintsControllerTest < ActionController::TestCase
  setup do
    @print = prints(:math_notes)
  end

  test 'should get index' do
    UserSession.create(users(:administrator))
    get :index
    assert_response :success
    assert_not_nil assigns(:prints)
    assert_select '#error_body', false
    assert_template 'prints/index'
  end

  test 'should get new' do
    UserSession.create(users(:administrator))
    get :new
    assert_response :success
    assert_not_nil assigns(:print)
    assert_select '#error_body', false
    assert_template 'prints/new'
  end

  test 'should create print' do
    UserSession.create(users(:administrator))
    assert_difference('Print.count') do
      post :create, :print => {
        :printer => Cups.default_printer || 'default'
      }
    end

    assert_redirected_to prints_path
    # Debe asignar el usuario autenticado como el creador de la impresión
    assert_equal users(:administrator).id, assigns(:print).user.id
  end

  test 'should show print' do
    UserSession.create(users(:administrator))
    get :show, :id => @print.to_param
    assert_response :success
    assert_not_nil assigns(:print)
    assert_select '#error_body', false
    assert_template 'prints/show'
  end

  test 'should get edit' do
    UserSession.create(users(:administrator))
    get :edit, :id => @print.to_param
    assert_response :success
    assert_not_nil assigns(:print)
    assert_select '#error_body', false
    assert_template 'prints/edit'
  end

  test 'should update print' do
    UserSession.create(users(:administrator))
    put :update, :id => @print.to_param, :print => {
      :printer => 'Updated printer'
    }
    assert_redirected_to prints_path
    assert_equal 'Updated printer', @print.reload.printer
  end

  test 'should destroy print' do
    UserSession.create(users(:administrator))
    assert_difference('Print.count', -1) do
      delete :destroy, :id => @print.to_param
    end

    assert_redirected_to prints_path
  end
end