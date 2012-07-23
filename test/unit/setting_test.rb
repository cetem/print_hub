require 'test_helper'

# Clase para probar el modelo "Setting"
class SettingTest < ActiveSupport::TestCase
  fixtures :settings

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @setting = Setting.find settings(:price_per_copy).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Setting, @setting
    assert_equal settings(:price_per_copy).var, @setting.var
    assert_equal settings(:price_per_copy).value, @setting.value
  end

  # Prueba la creación de una configuración
  test 'create' do
    assert_difference 'Setting.count' do
      Setting.new_value = 'new_value'
    end

    assert_equal 'new_value', Setting.new_value
  end

  # Prueba de actualización de un usuario
  test 'update' do
    assert_no_difference 'Setting.count' do
      assert @setting.update_attributes(value: 'Updated value'),
        @setting.errors.full_messages.join('; ')
    end

    assert_equal 'Updated value', @setting.reload.value
  end

  # Prueba de eliminación de usuarios
  test 'destroy' do
    assert_difference('Setting.count', -1) { @setting.destroy }
  end

  test 'the var name can not be changed' do
    original_var = @setting.var.dup

    @setting.var = 'new_name_of_var'
    assert @setting.save
    assert_not_equal original_var, 'new_name_of_var'
    assert_equal original_var, @setting.reload.var
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @setting.var = nil
    @setting.value = nil
    assert @setting.invalid?
    assert_equal 2, @setting.errors.count
    assert_equal [error_message_from_model(@setting, :var, :blank)],
      @setting.errors[:var]
    assert_equal [error_message_from_model(@setting, :value, :blank)],
      @setting.errors[:value]
  end
  
  test 'price parser and chooser' do
    Setting.price_per_one_sided_copy = '.10; >= 100 @ .08; >= 1000 @ .06'
    
    assert_equal '0.10', '%.2f' % PriceChooser.choose(one_sided: true)
    
    assert_equal(
      '0.10',
      '%.2f' % PriceChooser.choose(one_sided: true, copies: 2)
    )
    
    assert_equal(
      '0.08',
      '%.2f' % PriceChooser.choose(one_sided: true, copies: 100)
    )
    
    assert_equal(
      '0.08',
      '%.2f' % PriceChooser.choose(one_sided: true, copies: 101)
    )
    
    assert_equal(
      '0.08',
      '%.2f' % PriceChooser.choose(one_sided: true, copies: 999)
    )
    
    assert_equal(
      '0.06',
      '%.2f' % PriceChooser.choose(one_sided: true, copies: 1000)
    )
    
    assert_equal(
      '0.06',
      '%.2f' % PriceChooser.choose(one_sided: true, copies: 10000)
    )
  end
  
  test 'humanize price' do
    Setting.price_per_one_sided_copy = '.10; >= 100 @ .08; >= 1000 @ .06'
    Setting.price_per_two_sided_copy = '.10; >= 100 @ .08; >= 1000 @ .06'
    
    humanized = PriceChooser.humanize
    
    assert_equal 2, humanized.size
    assert humanized.all? { |type, values| values.size == 3 }
  end
end