require 'test_helper'

class DocumentsControllerTest < ActionController::TestCase
  setup do
    @document = documents(:math_book)
  end

  test "should get index" do
    UserSession.create(users(:administrator))
    get :index
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_select '#error_body', false
    assert_template 'documents/index'
  end

  test "should get new" do
    UserSession.create(users(:administrator))
    get :new
    assert_response :success
    assert_select '#error_body', false
    assert_template 'documents/new'
  end

  test "should create document" do
    UserSession.create(users(:administrator))
    assert_difference('Document.count') do
      post :create, :document => {
        :code => '0001234',
        :name => 'New Name',
        :description => 'New description'
      }
    end

    assert_redirected_to documents_path
  end

  test "should show document" do
    UserSession.create(users(:administrator))
    get :show, :id => @document.to_param
    assert_response :success
    assert_select '#error_body', false
    assert_template 'documents/show'
  end

  test "should get edit" do
    UserSession.create(users(:administrator))
    get :edit, :id => @document.to_param
    assert_response :success
    assert_select '#error_body', false
    assert_template 'documents/edit'
  end

  test "should update document" do
    UserSession.create(users(:administrator))
    put :update, :id => @document.to_param, :document => {
      :code => '003456',
      :name => 'Updated name',
      :description => 'Updated description'
    }
    assert_redirected_to documents_path
    assert_equal 'Updated name', @document.reload.name
  end

  test "should destroy document" do
    UserSession.create(users(:administrator))
    assert_difference('Document.count', -1) do
      delete :destroy, :id => @document.to_param
    end

    assert_redirected_to documents_path
  end
end