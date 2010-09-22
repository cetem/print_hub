require 'test_helper'

# Clase para probar el modelo "Document"
class DocumentTest < ActiveSupport::TestCase
  fixtures :documents

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @document = Document.find documents(:math_book).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Document, @document
    assert_equal documents(:math_book).code, @document.code
    assert_equal documents(:math_book).name, @document.name
    assert_equal documents(:math_book).description, @document.description
  end

  # Prueba la creación de un usuario
  test 'create' do
    assert_difference 'Document.count' do
      @document = Document.create(
        :code => '00001234',
        :name => 'New name',
        :description => 'New description'
      )
    end
  end

  # Prueba de actualización de un usuario
  test 'update' do
    assert_no_difference 'Document.count' do
      assert @document.update_attributes(:name => 'Updated name'),
        @document.errors.full_messages.join('; ')
    end

    assert_equal 'Updated name', @document.reload.name
  end

  # Prueba de eliminación de usuarios
  test 'destroy' do
    assert_difference('Document.count', -1) { @document.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @document.code = '  '
    @document.name = '  '
    assert @document.invalid?
    assert_equal 2, @document.errors.count
    assert_equal [error_message_from_model(@document, :code, :blank)],
      @document.errors[:code]
    assert_equal [error_message_from_model(@document, :name, :blank)],
      @document.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @document.code = documents(:math_notes).code
    assert @document.invalid?
    assert_equal 1, @document.errors.count
    assert_equal [error_message_from_model(@document, :code, :taken)],
      @document.errors[:code]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @document.code = 'abcde' * 52
    @document.name = 'abcde' * 52
    assert @document.invalid?
    assert_equal 2, @document.errors.count
    assert_equal [error_message_from_model(@document, :code, :too_long,
      :count => 255)], @document.errors[:code]
    assert_equal [error_message_from_model(@document, :name, :too_long,
      :count => 255)], @document.errors[:name]
  end
end