require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  setup do
    @tag = tags(:books)
    UserSession.create(users(:operator))
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:tags)
    assert_select 'nav ul.breadcrumb', false
    assert_select '#unexpected_error', false
    assert_template 'tags/index'
  end

  test 'should get nested index' do
    get :index, parent: tags(:notes)
    assert_response :success
    assert_not_nil assigns(:tags)
    assert_select 'nav ul.breadcrumb'
    assert_select '#unexpected_error', false
    assert_template 'tags/index'
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_not_nil assigns(:tag)
    assert_select '#unexpected_error', false
    assert_template 'tags/new'
  end

  test 'should create tag' do
    assert_difference ['Tag.count', 'Version.count'] do
      post :create, tag: {
        name: 'New tag'
      }
    end

    assert_redirected_to tags_path
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal users(:operator).id, Version.last.whodunnit
  end

  test 'should show tag' do
    get :show, id: @tag.to_param
    assert_response :success
    assert_not_nil assigns(:tag)
    assert_select '#unexpected_error', false
    assert_template 'tags/show'
  end

  test 'should get edit' do
    get :edit, id: @tag.to_param
    assert_response :success
    assert_not_nil assigns(:tag)
    assert_select '#unexpected_error', false
    assert_template 'tags/edit'
  end

  test 'should update tag' do
    put :update, id: @tag.to_param, tag: {
      name: 'Updated name'
    }
    assert_redirected_to tags_path
    assert_equal 'Updated name', @tag.reload.name
  end

  test 'should destroy tag' do
    assert_difference('Tag.count', -1) do
      delete :destroy, id: @tag.to_param
    end

    assert_redirected_to tags_path
  end
end
