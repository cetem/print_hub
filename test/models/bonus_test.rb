require 'test_helper'

# Clase para probar el modelo "Bonus"
class BonusTest < ActiveSupport::TestCase
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @bonus = credits(:big_bonus)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Bonus, @bonus
    assert_equal credits(:big_bonus).amount, @bonus.amount
    assert_equal credits(:big_bonus).remaining, @bonus.remaining
    assert_equal credits(:big_bonus).valid_until, @bonus.valid_until
    assert_equal credits(:big_bonus).customer_id, @bonus.customer_id
  end

  # Prueba la creación de una bonificación
  test 'create' do
    assert_difference 'Bonus.count' do
      @bonus = Bonus.create(
        amount: '100.00',
        remaining: '50.0',
        valid_until: 1.month.from_now.to_date,
        customer_id: customers(:student).id
      )
    end

    # Asignación automática del monto restante
    # No se puede inicializar en un valor menor al monto
    assert_equal '100.0', @bonus.reload.remaining.to_s
  end

  # Prueba de actualización de una bonificación
  test 'update' do
    assert_no_difference 'Bonus.count' do
      assert @bonus.update(
        amount: '1500.0',
        valid_until: 10.years.from_now.to_date
      ), @bonus.errors.full_messages.join('; ')
    end

    assert_equal 10.years.from_now.to_date, @bonus.reload.valid_until
    assert_not_equal '1500.0', @bonus.amount.to_s
    # No se debe poder alterar el valor inicial
    assert_equal '1000.0', @bonus.amount.to_s
  end

  # Prueba de eliminación de bonificaciones
  test 'destroy' do
    assert_difference('Bonus.count', -1) { @bonus.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @bonus.amount = nil
    @bonus.remaining = ' '
    assert @bonus.invalid?
    assert_equal 4, @bonus.errors.count
    assert_equal [error_message_from_model(@bonus, :amount, :blank),
      error_message_from_model(@bonus, :amount, :not_a_number)].sort,
      @bonus.errors[:amount].sort
    assert_equal [error_message_from_model(@bonus, :remaining, :blank),
      error_message_from_model(@bonus, :remaining, :not_a_number)].sort,
      @bonus.errors[:remaining].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @bonus.amount = '1.2x'
    @bonus.remaining = '1.2x'
    # TODO: Descomentar cuando corrijan el problema en validates_timeliness
    # @bonus.valid_until = '13/13/13'
    assert @bonus.invalid?
    assert_equal 2, @bonus.errors.count
    assert_equal [error_message_from_model(@bonus, :amount, :not_a_number)],
      @bonus.errors[:amount]
    assert_equal [error_message_from_model(@bonus, :remaining, :not_a_number)],
      @bonus.errors[:remaining]
#    assert_equal [error_message_from_model(@bonus, :valid_until,
#        :invalid_date)], @bonus.errors[:valid_until]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates boundaries of attributes' do
    @bonus.amount = '0'
    @bonus.remaining = '-0.01'
    @bonus.valid_until = 1.day.ago.to_date
    assert @bonus.invalid?
    assert_equal 3, @bonus.errors.count
    assert_equal [error_message_from_model(@bonus, :amount, :greater_than,
        count: 0)], @bonus.errors[:amount]
    assert_equal [error_message_from_model(@bonus, :remaining,
        :greater_than_or_equal_to, count: 0)], @bonus.errors[:remaining]
    assert_equal [error_message_from_model(@bonus, :valid_until, :on_or_after,
        restriction: I18n.l(Time.zone.today))], @bonus.errors[:valid_until]

    @bonus.reload
    @bonus.remaining = @bonus.amount + 1
    assert @bonus.invalid?
    assert_equal 1, @bonus.errors.count
    assert_equal [error_message_from_model(@bonus, :remaining,
        :less_than_or_equal_to, count: @bonus.amount)],
      @bonus.errors[:remaining]
  end
end
