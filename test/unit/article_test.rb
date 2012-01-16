require 'test_helper'

# Clase para probar el modelo "Article"
class ArticleTest < ActiveSupport::TestCase
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @article = Fabricate(:article)
  end

  # Prueba la creación de un artículo
  test 'create' do
    assert_difference 'Article.count' do
      @article = Article.create(Fabricate.attributes_for(:article))
    end
  end

  # Prueba de actualización de un artículos
  test 'update' do
    assert_no_difference 'Article.count' do
      assert @article.update_attributes(
        Fabricate.attributes_for(:article, name: 'Updated name')
      )
    end

    assert_equal 'Updated name', @article.reload.name
  end

  # Prueba de eliminación de artículos
  test 'destroy' do
    assert_difference('Article.count', -1) { @article.destroy }
  end

  test 'can not be destroyed' do
    # No se puede eliminar si ya se ha usado
    Fabricate(:article_line, article: @article)
    
    assert_no_difference('Article.count', -1) { @article.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @article.code = '  '
    @article.name = '  '
    @article.price = '  '
    assert @article.invalid?
    assert_equal 4, @article.errors.count
    assert_equal [error_message_from_model(@article, :code, :blank)],
      @article.errors[:code]
    assert_equal [error_message_from_model(@article, :name, :blank)],
      @article.errors[:name]
    assert_equal [
      error_message_from_model(@article, :price, :blank),
      error_message_from_model(@article, :price, :not_a_number)
    ].sort, @article.errors[:price].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @article.code = articles(:ringed).code
    assert @article.invalid?
    assert_equal 1, @article.errors.count
    assert_equal [error_message_from_model(@article, :code, :taken)],
      @article.errors[:code]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @article.name = 'abcde' * 52
    assert @article.invalid?
    assert_equal 1, @article.errors.count
    assert_equal [
      error_message_from_model(@article, :name, :too_long, count: 255)
    ], @article.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formatted attributes' do
    @article.price = '?xx'
    @article.code = '?xx'
    assert @article.invalid?
    assert_equal 2, @article.errors.count
    assert_equal [error_message_from_model(@article, :price, :not_a_number)],
      @article.errors[:price]
    assert_equal [error_message_from_model(@article, :code, :not_a_number)],
      @article.errors[:code]

    @article.price = '-0.01'
    @article.code = '-1'
    assert @article.invalid?
    assert_equal 2, @article.errors.count
    assert_equal [
      error_message_from_model(
        @article, :price, :greater_than_or_equal_to, count: 0
      )
    ], @article.errors[:price]
    assert_equal [
      error_message_from_model(@article, :code, :greater_than, count: 0)
    ], @article.errors[:code]
    
    @article.reload
    @article.code = '2147483648'
    assert @article.invalid?
    assert_equal 1, @article.errors.count
    assert_equal [
      error_message_from_model(@article, :code, :less_than, count: 2147483648)
    ], @article.errors[:code]

    @article.reload
    @article.code = '51.23'
    assert @article.invalid?
    assert_equal 1, @article.errors.count
    assert_equal [error_message_from_model(@article, :code, :not_an_integer)],
      @article.errors[:code]
  end
  
  test 'full text search' do
    new_article = Fabricate(:article)
    articles = Article.full_text([@article.name])
    
    assert_equal 1, articles.size
    assert_equal @article.name, articles.first.name
    
    articles = Article.full_text([@article.code.to_s])
    
    assert_equal 1, articles.size
    assert_equal @article.code, articles.first.code
    
    articles = Article.full_text([new_article.name])
    assert_equal 1, articles.size
    assert_equal new_article.name, articles.first.name
  end
end