require 'test_helper'

# Clase para probar el modelo "Payment"
class PaymentTest < ActiveSupport::TestCase
  fixtures :payments

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @payment = Payment.find payments(:big_and_cancelled).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Payment, @payment
    assert_equal payments(:big_and_cancelled).amount, @payment.amount
    assert_equal payments(:big_and_cancelled).paid, @payment.paid
  end

  # Prueba la creación de un usuario
  test 'create' do
    assert_difference 'Payment.count' do
      @payment = Payment.create(
        :amount => '10.50',
        :paid => '10.00'
      )
    end
  end

  # Prueba de actualización de un usuario
  test 'update' do
    assert_no_difference 'Payment.count' do
      assert @payment.update_attributes(:paid => '1900.00'),
        @payment.errors.full_messages.join('; ')
    end

    assert_equal BigDecimal.new('1900.00'), @payment.reload.paid
  end

  # Prueba de eliminación de usuarios
  test 'destroy' do
    assert_difference('Payment.count', -1) { @payment.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @payment.amount = nil
    @payment.paid = ' '
    assert @payment.invalid?
    assert_equal 4, @payment.errors.count
    assert_equal [error_message_from_model(@payment, :amount, :blank),
      error_message_from_model(@payment, :amount, :not_a_number)].sort,
      @payment.errors[:amount].sort
    assert_equal [error_message_from_model(@payment, :paid, :blank),
      error_message_from_model(@payment, :paid, :not_a_number)].sort,
      @payment.errors[:paid].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @payment.amount = '12x'
    @payment.paid = 'x'
    assert @payment.invalid?
    assert_equal 2, @payment.errors.count
    assert_equal [error_message_from_model(@payment, :amount, :not_a_number)],
      @payment.errors[:amount]
    assert_equal [error_message_from_model(@payment, :paid, :not_a_number)],
      @payment.errors[:paid]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates boundaries of attributes' do
    @payment.amount = '-0.01'
    @payment.paid = '-0.01'
    assert @payment.invalid?
    assert_equal 2, @payment.errors.count
    assert_equal [error_message_from_model(@payment, :amount,
        :greater_than_or_equal_to, :count => 0)], @payment.errors[:amount]
    assert_equal [error_message_from_model(@payment, :paid,
        :greater_than_or_equal_to, :count => 0)], @payment.errors[:paid]

    @payment.reload
    @payment.paid = @payment.amount + 0.01
    assert @payment.invalid?
    assert_equal 1, @payment.errors.count
    assert_equal [error_message_from_model(@payment, :paid,
        :less_than_or_equal_to, :count => @payment.amount)],
      @payment.errors[:paid]
  end
end