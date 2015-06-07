require 'test_helper'

# Clase para probar el modelo "OrderLine"
class OrderLineTest < ActiveSupport::TestCase
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @order_line = order_lines(:from_yesterday_math_notes)

    prepare_document_files
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of OrderLine, @order_line
    assert_equal order_lines(:from_yesterday_math_notes).copies,
                 @order_line.copies
    assert_equal order_lines(:from_yesterday_math_notes).price_per_copy,
                 @order_line.price_per_copy
    assert_equal order_lines(:from_yesterday_math_notes).print_job_type_id,
                 @order_line.print_job_type_id
    assert_equal order_lines(:from_yesterday_math_notes).document_id,
                 @order_line.document_id
    assert_equal order_lines(:from_yesterday_math_notes).order_id,
                 @order_line.order_id
  end

  # Prueba la creación de un ítem de una orden
  test 'create with document' do
    assert_difference 'OrderLine.count' do
      @order_line = OrderLine.create(copies: 2,
                                     price_per_copy: 1.10,
                                     print_job_type_id: print_job_types(:color).id,
                                     document_id: documents(:math_book).id)
    end

    # El precio por copia no se puede alterar
    price = PriceChooser.choose(
      type: print_job_types(:color).id,
      copies: documents(:math_book).pages * 2
    )
    assert_equal '%.2f' % price,
                 '%.2f' % @order_line.reload.price_per_copy
  end

  # Prueba de actualización de un ítem de una orden
  test 'update' do
    assert_no_difference 'OrderLine.count' do
      assert @order_line.update(copies: 20),
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

  test 'validates correct range of attributes' do
    @order_line.copies = '0'
    @order_line.price_per_copy = '-0.01'
    assert @order_line.invalid?
    assert_equal 2, @order_line.errors.count
    assert_equal [
      error_message_from_model(@order_line, :copies, :greater_than, count: 0)
    ], @order_line.errors[:copies]
    assert_equal [
      error_message_from_model(
        @order_line, :price_per_copy, :greater_than_or_equal_to, count: 0
      )
    ], @order_line.errors[:price_per_copy]

    @order_line.reload
    @order_line.copies = '2147483648'
    assert @order_line.invalid?
    assert_equal 1, @order_line.errors.count
    assert_equal [
      error_message_from_model(
        @order_line, :copies, :less_than, count: 2_147_483_648
      )
    ], @order_line.errors[:copies]
  end

  test 'price' do
    @order_line.copies = 35
    assert @order_line.valid?
    assert_equal '42.00', '%.2f' % @order_line.price

    @order_line.copies = 1
    assert @order_line.valid?
    assert_equal '1.20', '%.2f' % @order_line.price

    @order_line.copies = 1
    @order_line.document.pages = 1
    assert @order_line.valid?
    assert_equal '0.10', '%.2f' % @order_line.price

    @order_line.reload
    @order_line.copies = 1
    @order_line.print_job_type = print_job_types(:color)
    assert @order_line.valid?
    assert_equal '4.20', '%.2f' % @order_line.price # 12 * 0.35
  end
end
