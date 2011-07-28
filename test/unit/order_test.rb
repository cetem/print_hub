require 'test_helper'

# Clase para probar el modelo "Order"
class OrderTest < ActiveSupport::TestCase
  fixtures :orders

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @order = Order.find orders(:for_tomorrow).id
    
    prepare_settings
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Order, @order
    assert_equal orders(:for_tomorrow).scheduled_at, @order.scheduled_at
    assert_equal orders(:for_tomorrow).customer_id, @order.customer_id
  end

  # Prueba la creación de un pedido
  test 'create' do
    assert_difference ['Order.count', 'Version.count'] do
      @order = Order.create(
        :scheduled_at => 10.days.from_now,
        :customer => customers(:student_without_bonus)
      )
    end
  end
  
  test 'create with included documents' do
    assert_difference ['Order.count', 'OrderLine.count'] do
      @order = Order.create(
        :scheduled_at => 10.days.from_now,
        :customer => customers(:student_without_bonus),
        :include_documents => [documents(:math_book).id]
      )
    end
  end

  # Prueba de actualización de un pedido
  test 'update' do
    assert_no_difference 'Order.count' do
      assert @order.update_attributes(
        :scheduled_at => 5.days.from_now.at_midnight
      ), @order.errors.full_messages.join('; ')
    end

    assert_equal 5.days.from_now.at_midnight, @order.reload.scheduled_at
  end

  # Prueba de eliminación de pedidos
  test 'destroy' do
    assert_difference('Order.count', -1) { @order.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @order.scheduled_at = '  '
    @order.customer = nil
    assert @order.invalid?
    assert_equal 2, @order.errors.count
    assert_equal [error_message_from_model(@order, :scheduled_at, :blank)],
      @order.errors[:scheduled_at]
    assert_equal [error_message_from_model(@order, :customer, :blank)],
      @order.errors[:customer]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formatted attributes' do
    @order.scheduled_at = '13/13/13'
    assert @order.invalid?
    assert_equal 2, @order.errors.count
    assert_equal [
      error_message_from_model(@order, :scheduled_at, :blank),
      error_message_from_model(@order, :scheduled_at, :invalid_date)
    ].sort, @order.errors[:scheduled_at].sort
  end
  
  test 'price' do
    price = @order.order_lines.inject(0) { |t, ol| t + ol.price }

    assert @order.order_lines.any? { |ol| ol.price > 0 }
    assert @order.price > 0
    assert_equal @order.price, price
  end
end