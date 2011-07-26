require 'test_helper'

# Clase para probar el modelo "OrderLine"
class OrderLineTest < ActiveSupport::TestCase
  fixtures :order_lines

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @order_line = OrderLine.find order_lines(:from_yesterday_math_notes).id

    prepare_document_files
    prepare_settings
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of OrderLine, @order_line
    assert_equal order_lines(:from_yesterday_math_notes).copies,
      @order_line.copies
    assert_equal order_lines(:from_yesterday_math_notes).price_per_copy,
      @order_line.price_per_copy
    assert_equal order_lines(:from_yesterday_math_notes).range,
      @order_line.range
    assert_equal order_lines(:from_yesterday_math_notes).two_sided,
      @order_line.two_sided
    assert_equal order_lines(:from_yesterday_math_notes).document_id,
      @order_line.document_id
    assert_equal order_lines(:from_yesterday_math_notes).order_id,
      @order_line.order_id
  end

  # Prueba la creación de un ítem de una orden
  test 'create with document' do
    assert_difference 'OrderLine.count' do
      @order_line = OrderLine.create(
        :copies => 2,
        :price_per_copy => 1.10,
        :range => nil,
        :two_sided => false,
        :document => documents(:math_book)
      )
    end

    # El precio por copia no se puede alterar
    assert_equal Setting.price_per_one_sided_copy.to_s,
      '%.2f' % @order_line.reload.price_per_copy
  end

  # Prueba de actualización de un ítem de una orden
  test 'update' do
    assert_no_difference 'OrderLine.count' do
      assert @order_line.update_attributes(:copies => 20),
        @order_line.errors.full_messages.join('; ')
    end

    assert_equal 20, @order_line.reload.copies
  end

  # Prueba de eliminación de ítems de órdenes
  test 'destroy' do
    assert_difference('OrderLine.count', -1) { @order_line.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @order_line.copies = '  '
    @order_line.price_per_copy = '  '
    assert @order_line.invalid?
    assert_equal 2, @order_line.errors.count
    assert_equal [error_message_from_model(@order_line, :copies, :blank)],
      @order_line.errors[:copies]
    assert_equal [error_message_from_model(@order_line, :price_per_copy,
        :blank)], @order_line.errors[:price_per_copy]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @order_line.copies = '?xx'
    @order_line.price_per_copy = '?xx'
    assert @order_line.invalid?
    assert_equal 2, @order_line.errors.count
    assert_equal [error_message_from_model(@order_line, :copies, :not_a_number)],
      @order_line.errors[:copies]
    assert_equal [error_message_from_model(@order_line, :price_per_copy,
        :not_a_number)], @order_line.errors[:price_per_copy]
  end

  test 'validates integer attributes' do
    @order_line.copies = '1.23'
    @order_line.price_per_copy = '1.23'
    assert @order_line.invalid?
    assert_equal 1, @order_line.errors.count
    assert_equal [error_message_from_model(@order_line, :copies, :not_an_integer)],
      @order_line.errors[:copies]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates attributes length' do
    @order_line.range = 'abcde' * 52
    assert @order_line.invalid?
    assert_equal 2, @order_line.errors.count
    assert_equal [error_message_from_model(@order_line, :range, :too_long,
        :count => 255), error_message_from_model(@order_line, :range,
        :invalid)].sort, @order_line.errors[:range].sort
  end

  test 'validates correct range of attributes' do
    @order_line.copies = '0'
    @order_line.price_per_copy = '-0.01'
    assert @order_line.invalid?
    assert_equal 2, @order_line.errors.count
    assert_equal [error_message_from_model(@order_line, :copies, :greater_than,
        :count => 0)], @order_line.errors[:copies]
    assert_equal [error_message_from_model(@order_line, :price_per_copy,
        :greater_than_or_equal_to, :count => 0)],
      @order_line.errors[:price_per_copy]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates ranges' do
    @order_line.range = '1x'
    assert @order_line.invalid?
    assert_equal 1, @order_line.errors.count
    assert_equal [error_message_from_model(@order_line, :range, :invalid)],
      @order_line.errors[:range]

    @order_line.range = '0'
    assert @order_line.invalid?
    assert_equal 1, @order_line.errors.count
    assert_equal [error_message_from_model(@order_line, :range, :invalid)],
      @order_line.errors[:range]

    @order_line.range = '1-'
    assert @order_line.invalid?
    assert_equal 1, @order_line.errors.count
    assert_equal [error_message_from_model(@order_line, :range, :invalid)],
      @order_line.errors[:range]

    @order_line.range = '1, 2-'
    assert @order_line.invalid?
    assert_equal 1, @order_line.errors.count
    assert_equal [error_message_from_model(@order_line, :range, :invalid)],
      @order_line.errors[:range]

    @order_line.range = '2x, 10'
    assert @order_line.invalid?
    assert_equal 1, @order_line.errors.count
    assert_equal [error_message_from_model(@order_line, :range, :invalid)],
      @order_line.errors[:range]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates ranges overlap' do
    @order_line.range = '1,2-4,4-5'
    assert @order_line.invalid?
    assert_equal 1, @order_line.errors.count
    assert_equal [error_message_from_model(@order_line, :range, :overlapped)],
      @order_line.errors[:range]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates too long ranges' do
    @order_line.range = '1,1500'
    assert @order_line.invalid?
    assert_equal 1, @order_line.errors.count
    assert_equal [error_message_from_model(@order_line, :range, :too_long,
        :count => @order_line.document.pages)], @order_line.errors[:range]
  end
end
