require 'test_helper'
# Clase para probar el modelo "Credit"
class CreditTest < ActiveSupport::TestCase
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @credit = credits(:big_bonus)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Credit, @credit
    assert_equal credits(:big_bonus).amount, @credit.amount
    assert_equal credits(:big_bonus).remaining, @credit.remaining
    assert_equal credits(:big_bonus).valid_until, @credit.valid_until
    assert_equal credits(:big_bonus).customer_id, @credit.customer_id
  end

  # Prueba la creación de un crédito
  test 'create' do
    assert_difference 'Credit.count' do
      @credit = Credit.create(
        amount: '100.00',
        remaining: '50.0',
        valid_until: 1.month.from_now.to_date,
        customer_id: customers(:student).id
      )
    end

    # Asignación automática del monto restante
    # No se puede inicializar en un valor menor al monto
    assert_equal '100.0', @credit.reload.remaining.to_s
  end

  # Prueba de actualización de un crédito
  test 'update' do
    assert_no_difference 'Credit.count' do
      assert @credit.update(
        amount: '1500.0',
        valid_until: 10.years.from_now.to_date
      ), @credit.errors.full_messages.join('; ')
    end

    assert_equal 10.years.from_now.to_date, @credit.reload.valid_until
    assert_not_equal '1500.0', @credit.amount.to_s
    # No se debe poder alterar el valor inicial
    assert_equal '1000.0', @credit.amount.to_s
  end

  # Prueba de eliminación de créditos
  test 'destroy' do
    assert_difference('Credit.count', -1) { @credit.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @credit.amount = nil
    @credit.remaining = ' '
    assert @credit.invalid?
    assert_equal 4, @credit.errors.count
    assert_equal [error_message_from_model(@credit, :amount, :blank),
      error_message_from_model(@credit, :amount, :not_a_number)].sort,
      @credit.errors[:amount].sort
    assert_equal [error_message_from_model(@credit, :remaining, :blank),
      error_message_from_model(@credit, :remaining, :not_a_number)].sort,
      @credit.errors[:remaining].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @credit.amount = '1.2x'
    @credit.remaining = '1.2x'
    # TODO: Descomentar cuando corrijan el problema en validates_timeliness
    # @credit.valid_until = '13/13/13'
    assert @credit.invalid?
    assert_equal 2, @credit.errors.count
    assert_equal [error_message_from_model(@credit, :amount, :not_a_number)],
      @credit.errors[:amount]
    assert_equal [error_message_from_model(@credit, :remaining, :not_a_number)],
      @credit.errors[:remaining]
#    assert_equal [error_message_from_model(@credit, :valid_until,
#        :invalid_date)], @credit.errors[:valid_until]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates boundaries of attributes' do
    @credit.amount = '0'
    @credit.remaining = '-0.01'
    @credit.valid_until = 1.day.ago.to_date
    assert @credit.invalid?
    assert_equal 3, @credit.errors.count
    assert_equal [error_message_from_model(@credit, :amount, :greater_than,
        count: 0)], @credit.errors[:amount]
    assert_equal [error_message_from_model(@credit, :remaining,
        :greater_than_or_equal_to, count: 0)], @credit.errors[:remaining]
    assert_equal [error_message_from_model(@credit, :valid_until, :on_or_after,
        restriction: I18n.l(Time.zone.today))], @credit.errors[:valid_until]

    @credit.reload
    @credit.remaining = @credit.amount + 1
    assert @credit.invalid?
    assert_equal 1, @credit.errors.count
    assert_equal [error_message_from_model(@credit, :remaining,
        :less_than_or_equal_to, count: @credit.amount)],
      @credit.errors[:remaining]
  end

  test 'still valid' do
    @credit.valid_until = nil

    assert @credit.still_valid?

    @credit.valid_until = 1.day.from_now.to_date

    assert @credit.still_valid?

    @credit.valid_until = Date.today

    assert @credit.still_valid?

    @credit.valid_until = 1.day.ago.to_date

    assert !@credit.still_valid?
  end
end
