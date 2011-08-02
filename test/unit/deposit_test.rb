require 'test_helper'

# Clase para probar el modelo "Deposit"
class DepositTest < ActiveSupport::TestCase
  fixtures :credits

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @deposit = Deposit.find(credits(:big_deposit).id)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Deposit, @deposit
    assert_equal credits(:big_deposit).amount, @deposit.amount
    assert_equal credits(:big_deposit).remaining, @deposit.remaining
    assert_equal credits(:big_deposit).valid_until, @deposit.valid_until
    assert_equal credits(:big_deposit).customer_id, @deposit.customer_id
  end

  # Prueba la creación de un depósito
  test 'create' do
    assert_difference 'Deposit.count' do
      @deposit = Deposit.create(
        :amount => '100.00',
        :remaining => '50.0',
        :valid_until => 1.month.from_now.to_date,
        :customer => customers(:student)
      )
    end

    # Asignación automática del monto restante
    # No se puede inicializar en un valor menor al monto
    assert_equal '100.0', @deposit.reload.remaining.to_s
  end

  # Prueba de actualización de un depósito
  test 'update' do
    assert_no_difference 'Deposit.count' do
      assert @deposit.update_attributes(
        :amount => '1500.0',
        :valid_until => 10.years.from_now.to_date
      ), @deposit.errors.full_messages.join('; ')
    end

    assert_equal 10.years.from_now.to_date, @deposit.reload.valid_until
    assert_not_equal '1500.0', @deposit.amount.to_s
    # No se debe poder alterar el valor inicial
    assert_equal '1000.0', @deposit.amount.to_s
  end

  # Prueba de eliminación de depósitos
  test 'destroy' do
    assert_difference('Deposit.count', -1) { @deposit.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @deposit.amount = nil
    @deposit.remaining = ' '
    assert @deposit.invalid?
    assert_equal 4, @deposit.errors.count
    assert_equal [error_message_from_model(@deposit, :amount, :blank),
      error_message_from_model(@deposit, :amount, :not_a_number)].sort,
      @deposit.errors[:amount].sort
    assert_equal [error_message_from_model(@deposit, :remaining, :blank),
      error_message_from_model(@deposit, :remaining, :not_a_number)].sort,
      @deposit.errors[:remaining].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @deposit.amount = '1.2x'
    @deposit.remaining = '1.2x'
    # TODO: Descomentar cuando corrijan el problema en validates_timeliness
    #@deposit.valid_until = '13/13/13'
    assert @deposit.invalid?
    assert_equal 2, @deposit.errors.count
    assert_equal [error_message_from_model(@deposit, :amount, :not_a_number)],
      @deposit.errors[:amount]
    assert_equal [error_message_from_model(@deposit, :remaining, :not_a_number)],
      @deposit.errors[:remaining]
#    assert_equal [error_message_from_model(@deposit, :valid_until,
#        :invalid_date)], @deposit.errors[:valid_until]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates boundaries of attributes' do
    @deposit.amount = '0'
    @deposit.remaining = '-0.01'
    @deposit.valid_until = 1.day.ago.to_date
    assert @deposit.invalid?
    assert_equal 3, @deposit.errors.count
    assert_equal [error_message_from_model(@deposit, :amount, :greater_than,
        :count => 0)], @deposit.errors[:amount]
    assert_equal [error_message_from_model(@deposit, :remaining,
        :greater_than_or_equal_to, :count => 0)], @deposit.errors[:remaining]
    assert_equal [error_message_from_model(@deposit, :valid_until, :on_or_after,
        :restriction => I18n.l(Date.today))], @deposit.errors[:valid_until]

    @deposit.reload
    @deposit.remaining = @deposit.amount + 1
    assert @deposit.invalid?
    assert_equal 1, @deposit.errors.count
    assert_equal [error_message_from_model(@deposit, :remaining,
        :less_than_or_equal_to, :count => @deposit.amount)],
      @deposit.errors[:remaining]
  end
end