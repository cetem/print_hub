require 'test_helper'

# Clase para probar el modelo "Shift"
class ShiftTest < ActiveSupport::TestCase
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @shift = shifts(:current_shift)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Shift, @shift
    assert_equal shifts(:current_shift).start, @shift.start
    assert_equal shifts(:current_shift).finish, @shift.finish
    assert_equal shifts(:current_shift).description, @shift.description
    assert_equal shifts(:current_shift).user_id, @shift.user_id
  end

  # Prueba la creación de un turno
  test 'create' do
    assert_difference 'Shift.count' do
      @shift = Shift.create(
        start: 10.minutes.ago,
        finish: nil,
        description: 'Some shift',
        user_id: users(:operator).id,
        paid: false
      )
    end
  end

  # Prueba actualizar final de un turno
  test 'update ' do
    10.minute.ago.to_datetime.tap do |start|
      1.minute.ago.to_datetime.tap do |finish|
        assert_no_difference 'Shift.count' do
          assert @shift.update(start: start, finish: finish),
            @shift.errors.full_messages.join('; ')
        end

        assert_equal start.to_i, @shift.reload.start.to_i
        assert_equal finish.to_i, @shift.finish.to_i
      end
    end
  end

  # Prueba de eliminación de turnos
  test 'destroy' do
    assert_difference('Shift.count', -1) { @shift.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @shift.start = '  '
    @shift.user_id = nil
    assert @shift.invalid?
    assert_equal 2, @shift.errors.count
    assert_equal [error_message_from_model(@shift, :start, :blank)],
      @shift.errors[:start]
    assert_equal [error_message_from_model(@shift, :user_id, :blank)],
      @shift.errors[:user_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formatted attributes' do
    @shift.start = '13/13/13'
    @shift.finish = '13/13/13'
    assert @shift.invalid?
    assert_equal 3, @shift.errors.count
    assert_equal [
      error_message_from_model(@shift, :start, :invalid_date),
      error_message_from_model(@shift, :start, :blank)
    ].sort, @shift.errors[:start].sort
    assert_equal [error_message_from_model(@shift, :finish, :invalid_date)],
      @shift.errors[:finish]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates attributes boundaries' do
    @shift.finish = @shift.start - 1
    assert @shift.invalid?
    assert_equal 2, @shift.errors.count
    assert_equal [
      error_message_from_model(
        @shift, :start, :before,
        restriction: @shift.finish.strftime(
          I18n.t('validates_timeliness.error_value_formats.datetime')
        )
      )
    ], @shift.errors[:start]
    assert_equal [
      error_message_from_model(
        @shift, :finish, :after,
        restriction: @shift.start.strftime(
          I18n.t('validates_timeliness.error_value_formats.datetime')
        )
      )
    ], @shift.errors[:finish]
  end

  # Prueba que no cierren un turno después del limite
  test 'validate finish the shift before the limit' do
    @shift.finish = @shift.finish_limit + 1.minute
    assert @shift.invalid?
    assert_equal 2, @shift.errors.count
    assert_equal [
      error_message_from_model(
        @shift, :start, :after, restriction: I18n.l(
          @shift.start_limit, format: '%d/%m/%Y %H:%M:%S'
        )
      )
    ], @shift.errors[:start]
    assert_equal [
      error_message_from_model(
        @shift, :finish, :before, restriction: I18n.l(
          @shift.finish_limit, format: '%d/%m/%Y %H:%M:%S'
        )
      )
    ], @shift.errors[:finish]
  end

  test 'pay a pending shift' do
    @shift = shifts(:old_shift)

    assert_difference('Shift.pay_pending.count', -1) { assert @shift.pay! }
  end

  test 'not pay a paid shift' do
    @shift = shifts(:paid_shift)

    assert_no_difference('Shift.pay_pending.count') { assert @shift.pay! }
  end
end
