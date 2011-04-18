require 'test_helper'

class ArticlesControllerTest < ActionController::TestCase
  setup do
    @article = articles(:binding)
  end

  test 'should get index' do
    UserSession.create(users(:administrator))
    get :index
    assert_response :success
    assert_not_nil assigns(:articles)
    assert_select '#error_body', false
    assert_template 'articles/index'
  end

  test 'should get new' do
    UserSession.create(users(:administrator))
    get :new
    assert_response :success
    assert_select '#error_body', false
    assert_template 'articles/new'
  end

  test 'should create article' do
    UserSession.create(users(:administrator))
    assert_difference ['Article.count', 'Version.count'] do
      post :create, :article => {
        :code => '0001234',
        :name => 'New Name',
        :price => '15.2',
        :description => 'New description'
      }
    end

    assert_redirected_to articles_path
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal users(:administrator).id, Version.last.whodunnit
  end

  test 'should show article' do
    UserSession.create(users(:administrator))
    get :show, :id => @article.to_param
    assert_response :success
    assert_select '#error_body', false
    assert_template 'articles/show'
  end

  test 'should get edit' do
    UserSession.create(users(:administrator))
    get :edit, :id => @article.to_param
    assert_response :success
    assert_select '#error_body', false
    assert_template 'articles/edit'
  end

  test 'should update article' do
    UserSession.create(users(:administrator))
    put :update, :id => @article.to_param, :article => {
      :code => '003456',
      :name => 'Updated name',
      :price => '15.2',
      :description => 'Updated description'
    }
    assert_redirected_to articles_path
    assert_equal 'Updated name', @article.reload.name
  end

  test 'should destroy article' do
    UserSession.create(users(:administrator))

    article = Article.find(articles(:ringed).id)

    assert_difference('Article.count', -1) do
      delete :destroy, :id => article.to_param
    end

    assert_redirected_to articles_path
  end
end