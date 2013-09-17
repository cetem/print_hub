require 'test_helper'

class ArticlesControllerTest < ActionController::TestCase
  setup do
    @article = articles(:binding)
    UserSession.create(users(:administrator))
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:articles)
    assert_select '#unexpected_error', false
    assert_template 'articles/index'
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'articles/new'
  end

  test 'should create article' do
    assert_difference ['Article.count', 'Version.count'] do
      post :create, article: {
        code: '0001234',
        name: 'New Name',
        price: '15.2',
        description: 'New description'
      }
    end

    assert_redirected_to articles_path
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal users(:administrator).id, Version.last.whodunnit
  end

  test 'should show article' do
    get :show, id: @article.to_param
    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'articles/show'
  end

  test 'should get edit' do
    get :edit, id: @article.to_param
    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'articles/edit'
  end

  test 'should update article' do
    put :update, id: @article.to_param, article: {
      code: '003456',
      name: 'Updated name',
      price: '15.2',
      description: 'Updated description'
    }
    assert_redirected_to articles_path
    assert_equal 'Updated name', @article.reload.name
  end

  test 'should destroy article' do
    article = Article.find(articles(:ringed).id)

    assert_difference('Article.count', -1) do
      delete :destroy, id: article.to_param
    end

    assert_redirected_to articles_path
  end
end
