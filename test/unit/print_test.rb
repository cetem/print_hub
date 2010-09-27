require 'test_helper'

# Clase para probar el modelo "Print"
class PrintTest < ActiveSupport::TestCase
  fixtures :prints

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @print = Print.find prints(:math_notes).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Print, @print
    assert_equal prints(:math_notes).printer, @print.printer
    assert_equal prints(:math_notes).user_id, @print.user_id
  end

  # Prueba la creación de una impresión
  test 'create' do
    assert_difference 'Print.count' do
      @print = Print.create(
        :printer => Cups.default_printer || 'default',
        :user => users(:administrator)
      )
    end
  end

  # Prueba de actualización de una impresión
  test 'update' do
    assert_no_difference 'Print.count' do
      assert @print.update_attributes(:printer => 'Updated printer'),
        @print.errors.full_messages.join('; ')
    end

    assert_equal 'Updated printer', @print.reload.printer
  end

  # Prueba de eliminación de impresiones
  test 'destroy' do
    assert_difference('Print.count', -1) { @print.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @print.printer = '   '
    assert @print.invalid?
    assert_equal 1, @print.errors.count
    assert_equal [error_message_from_model(@print, :printer, :blank)],
      @print.errors[:printer]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @print.printer = 'abcde' * 52
    assert @print.invalid?
    assert_equal 1, @print.errors.count
    assert_equal [error_message_from_model(@print, :printer, :too_long,
      :count => 255)], @print.errors[:printer]
  end
end