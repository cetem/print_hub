require 'test_helper'

# Clase para probar el modelo "Tag"
class TagTest < ActiveSupport::TestCase
  fixtures :tags

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @tag = Tag.find tags(:books).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Tag, @tag
    assert_equal tags(:books).name, @tag.name
    assert_equal tags(:books).parent_id, @tag.parent_id
  end

  # Prueba la creación de un usuario
  test 'create' do
    assert_difference 'Tag.count' do
      @tag = Tag.create(:name => 'New name')
    end
  end

  # Prueba de actualización de un usuario
  test 'update' do
    assert_no_difference 'Tag.count' do
      assert @tag.update_attributes(:name => 'Updated name'),
        @tag.errors.full_messages.join('; ')
    end

    assert_equal 'Updated name', @tag.reload.name
  end

  # Prueba de eliminación de usuarios
  test 'destroy' do
    assert_difference('Tag.count', -1) { @tag.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @tag.name = '  '
    assert @tag.invalid?
    assert_equal 1, @tag.errors.count
    assert_equal [error_message_from_model(@tag, :name, :blank)],
      @tag.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @tag.name = tags(:notes).name
    assert @tag.invalid?
    assert_equal 1, @tag.errors.count
    assert_equal [error_message_from_model(@tag, :name, :taken)],
      @tag.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @tag.name = 'abcde' * 52
    assert @tag.invalid?
    assert_equal 1, @tag.errors.count
    assert_equal [error_message_from_model(@tag, :name, :too_long,
      :count => 255)], @tag.errors[:name]
  end
end