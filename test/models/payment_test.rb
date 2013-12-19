require 'test_helper'

# Clase para probar el modelo "Payment"
class PaymentTest < ActiveSupport::TestCase
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @payment = payments(:math_payment)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Payment, @payment
    assert_equal payments(:math_payment).amount, @payment.amount
    assert_equal payments(:math_payment).paid, @payment.paid
    assert_equal payments(:math_payment).paid_with, @payment.paid_with
    assert_equal payments(:math_payment).payable_id, @payment.payable_id
    assert_equal payments(:math_payment).payable_type, @payment.payable_type
  end

  # Prueba la creación de un pago
  test 'create' do
    assert_difference 'Payment.count' do
      @payment = Payment.create(
        amount: '10.50',
        paid: '10.00',
        paid_with: Payment::PAID_WITH[:credit],
        payable_id: prints(:math_print).id
      )
    end
  end

  # Prueba de actualización de un pago
  test 'update' do
    assert_no_difference 'Payment.count' do
      assert @payment.update(paid: '38.00'),
        @payment.errors.full_messages.join('; ')
    end

    assert_equal BigDecimal.new('38.00'), @payment.reload.paid
  end

  # Prueba de eliminación de pagos
  test 'destroy' do
    assert_difference('Payment.count', -1) { @payment.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @payment.amount = nil
    @payment.paid = ' '
    @payment.paid_with = ' '
    assert @payment.invalid?
    assert_equal 6, @payment.errors.count
    assert_equal [error_message_from_model(@payment, :amount, :blank),
      error_message_from_model(@payment, :amount, :not_a_number)].sort,
      @payment.errors[:amount].sort
    assert_equal [error_message_from_model(@payment, :paid, :blank),
      error_message_from_model(@payment, :paid, :not_a_number)].sort,
      @payment.errors[:paid].sort
    assert_equal [error_message_from_model(@payment, :paid_with, :blank),
      error_message_from_model(@payment, :paid_with, :inclusion)].sort,
      @payment.errors[:paid_with].sort
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
  test 'validates length of attributes' do
    @payment.paid_with = 'xx'
    assert @payment.invalid?
    assert_equal 2, @payment.errors.count
    assert_equal [error_message_from_model(@payment, :paid_with, :inclusion),
      error_message_from_model(@payment, :paid_with, :too_long,
        count: 1)].sort, @payment.errors[:paid_with].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates inclusion of attributes' do
    @payment.paid_with = 'x'
    assert @payment.invalid?
    assert_equal 1, @payment.errors.count
    assert_equal [error_message_from_model(@payment, :paid_with, :inclusion)],
      @payment.errors[:paid_with].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates boundaries of attributes' do
    @payment.amount = '0.00'
    @payment.paid = '-0.01'
    assert @payment.invalid?
    assert_equal 2, @payment.errors.count
    assert_equal [error_message_from_model(@payment, :amount,
        :greater_than, count: 0)], @payment.errors[:amount]
    assert_equal [error_message_from_model(@payment, :paid,
        :greater_than_or_equal_to, count: 0)], @payment.errors[:paid]

    @payment.reload
    @payment.paid = @payment.amount + 0.01
    assert @payment.invalid?
    assert_equal 1, @payment.errors.count
    assert_equal [error_message_from_model(@payment, :paid,
        :less_than_or_equal_to, count: @payment.amount)],
      @payment.errors[:paid]
  end

  test 'dynamic paid with functions' do
    Payment::PAID_WITH.each do |paid_with, value|
      @payment.paid_with = value
      assert @payment.send(:"#{paid_with}?")

      Payment::PAID_WITH.each do |k, v|
        unless k == paid_with
          @payment.paid_with = v
          assert !@payment.send(:"#{paid_with}?")
        end
      end
    end
  end
end
