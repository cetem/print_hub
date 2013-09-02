require 'test_helper'

# Clase para probar el modelo "Article"
class ArticleTest < ActiveSupport::TestCase
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @article = Article.find articles(:binding).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Article, @article
    assert_equal articles(:binding).code, @article.code
    assert_equal articles(:binding).name, @article.name
    assert_equal articles(:binding).price, @article.price
    assert_equal articles(:binding).description, @article.description
  end

  # Prueba la creación de un articleo
  test 'create' do
    assert_difference 'Article.count' do
      @article = Article.create(
        code: '00001234',
        name: 'New name',
        price: '15.2',
        description: 'New description'
      )
    end
  end

  # Prueba de actualización de un articleo
  test 'update' do
    assert_no_difference 'Article.count' do
      assert @article.update_attributes(name: 'Updated name'),
        @article.errors.full_messages.join('; ')
    end

    assert_equal 'Updated name', @article.reload.name
  end

  # Prueba de eliminación de articleos
  test 'destroy' do
    article = Article.find(articles(:ringed).id)

    assert_difference('Article.count', -1) { article.destroy }
  end

  test 'can not be destroyed' do
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
    assert_equal [error_message_from_model(@article, :price,
        :greater_than_or_equal_to, count: 0)], @article.errors[:price]
    assert_equal [error_message_from_model(@article, :code, :greater_than,
        count: 0)], @article.errors[:code]
    
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
    articles = Article.full_text(['Ringed'])
    
    assert_equal 1, articles.size
    assert_equal 'Ringed', articles.first.name
    
    articles = Article.full_text(['111'])
    
    assert_equal 1, articles.size
    assert_equal 111, articles.first.code
  end
end
