require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  setup do
    @tag = tags(:books)
  end

  test 'should get index' do
    UserSession.create(users(:administrator))
    get :index
    assert_response :success
    assert_not_nil assigns(:tags)
    assert_select 'nav.path', false
    assert_select '#error_body', false
    assert_template 'tags/index'
  end

  test 'should get nested index' do
    UserSession.create(users(:administrator))
    get :index, :parent => tags(:notes)
    assert_response :success
    assert_not_nil assigns(:tags)
    assert_select 'nav.path'
    assert_select '#error_body', false
    assert_template 'tags/index'
  end

  test 'should get new' do
    UserSession.create(users(:administrator))
    get :new
    assert_response :success
    assert_not_nil assigns(:tag)
    assert_select '#error_body', false
    assert_template 'tags/new'
  end

  test 'should create tag' do
    UserSession.create(users(:administrator))
    assert_difference('Tag.count') do
      post :create, :tag => {
        :name => 'New tag'
      }
    end

    assert_redirected_to tags_path
  end

  test 'should show tag' do
    UserSession.create(users(:administrator))
    get :show, :id => @tag.to_param
    assert_response :success
    assert_not_nil assigns(:tag)
    assert_select '#error_body', false
    assert_template 'tags/show'
  end

  test 'should get edit' do
    UserSession.create(users(:administrator))
    get :edit, :id => @tag.to_param
    assert_response :success
    assert_not_nil assigns(:tag)
    assert_select '#error_body', false
    assert_template 'tags/edit'
  end

  test 'should update tag' do
    UserSession.create(users(:administrator))
    put :update, :id => @tag.to_param, :tag => {
      :name => 'Updated name'
    }
    assert_redirected_to tags_path
    assert_equal 'Updated name', @tag.reload.name
  end

  test 'should destroy tag' do
    UserSession.create(users(:administrator))
    assert_difference('Tag.count', -1) do
      delete :destroy, :id => @tag.to_param
    end

    assert_redirected_to tags_path
  end
end