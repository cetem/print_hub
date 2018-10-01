require 'test_helper'

class ArticlesControllerTest < ActionController::TestCase
  setup do
    @article = articles(:binding)
    @operator = users(:operator)

    sign_in(@operator)
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:articles)
    # assert_select '#unexpected_error', false
    assert_template 'articles/index'
  end

  test 'should get new' do
    get :new
    assert_response :success
    # assert_select '#unexpected_error', false
    assert_template 'articles/new'
  end

  test 'should create article' do
    assert_difference ['Article.count', 'PaperTrail::Version.count'] do
      post :create, params: {
        article: {
          code: '0001234',
          name: 'New Name',
          price: '15.2',
          description: 'New description'
        }
      }
    end

    assert_redirected_to articles_path
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal @operator.id, PaperTrail::Version.last.whodunnit
  end

  test 'should show article' do
    get :show, params: { id: @article.to_param }
    assert_response :success
    # assert_select '#unexpected_error', false
    assert_template 'articles/show'
  end

  test 'should get edit' do
    get :edit, params: { id: @article.to_param }
    assert_response :success
    # assert_select '#unexpected_error', false
    assert_template 'articles/edit'
  end

  test 'should update article' do
    put :update, params: { id: @article.to_param, article: {
      code: '003456',
      name: 'Updated name',
      price: '15.2',
      description: 'Updated description'
    } }
    assert_redirected_to articles_path
    assert_equal 'Updated name', @article.reload.name
  end

  test 'should destroy article' do
    article = articles(:ringed)

    assert_difference('Article.count', -1) do
      delete :destroy, params: { id: article.to_param }
    end

    assert_redirected_to articles_path
  end
end
