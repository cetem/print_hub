require 'test_helper'

# Clase para probar el modelo "ArticleLine"
class ArticleLineTest < ActiveSupport::TestCase
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @article_line = ArticleLine.find article_lines(:math_binding_line).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of ArticleLine, @article_line
    assert_equal article_lines(:math_binding_line).article_id,
      @article_line.article_id
    assert_equal article_lines(:math_binding_line).print_id,
      @article_line.print_id
    assert_equal article_lines(:math_binding_line).units, @article_line.units
    assert_equal article_lines(:math_binding_line).unit_price,
      @article_line.unit_price
  end

  # Prueba la creación de una línea de artículo
  test 'create' do
    assert_difference 'ArticleLine.count' do
      @article_line = ArticleLine.create({
        article_id: articles(:binding).id,
        print_id: prints(:math_print).id,
        units: 1,
        unit_price: articles(:binding).price
      })
    end
  end

  # Prueba de actualización de una línea de artículo
  test 'update' do
    assert_no_difference 'ArticleLine.count' do
      assert @article_line.update_attributes(units: 100),
        @article_line.errors.full_messages.join('; ')
    end

    # No se puede modificar el atributo
    assert_not_equal 100, @article_line.reload.units
  end

  # Prueba de eliminación de líneas de artículos
  test 'destroy' do
    assert_difference('ArticleLine.count', -1) { @article_line.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @article_line.article_id = nil
    @article_line.units = nil
    @article_line.unit_price = '   '
    assert @article_line.invalid?
    assert_equal 3, @article_line.errors.count
    assert_equal [error_message_from_model(@article_line, :article_id, :blank)],
      @article_line.errors[:article_id]
    assert_equal [error_message_from_model(@article_line, :units, :blank)],
      @article_line.errors[:units]
    assert_equal [error_message_from_model(@article_line, :unit_price, :blank)],
      @article_line.errors[:unit_price]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @article_line.units = '1.2'
    @article_line.unit_price = '1X2'
    assert @article_line.invalid?
    assert_equal 2, @article_line.errors.count
    assert_equal [error_message_from_model(@article_line, :units,
        :not_an_integer)], @article_line.errors[:units]
    assert_equal [error_message_from_model(@article_line, :unit_price,
        :not_a_number)], @article_line.errors[:unit_price]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates attributes boundaries' do
    @article_line.unit_price = '-0.01'
    @article_line.units = '0'
    assert @article_line.invalid?
    assert_equal 2, @article_line.errors.count
    assert_equal [
      error_message_from_model(
        @article_line, :unit_price, :greater_than_or_equal_to, count: 0
      )
    ], @article_line.errors[:unit_price]
    assert_equal [
      error_message_from_model(@article_line, :units, :greater_than, count: 0)
    ], @article_line.errors[:units]
    
    @article_line.reload
    @article_line.units = '2147483648'
    assert @article_line.invalid?
    assert_equal 1, @article_line.errors.count
    assert_equal [
      error_message_from_model(
        @article_line, :units, :less_than, count: 2147483648
      )
    ], @article_line.errors[:units]
  end

  test 'price' do
    assert_equal '3.58', @article_line.price.to_s
  end
end
