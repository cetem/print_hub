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

  # Prueba la creación de una etiqueta
  test 'create' do
    assert_difference 'Tag.count' do
      @tag = Tag.create(name: 'New name')
    end
  end

  # Prueba de actualización de una etiqueta
  test 'update' do
    assert_no_difference 'Tag.count' do
      assert @tag.update_attributes(name: 'Updated name'),
        @tag.errors.full_messages.join('; ')
    end

    assert_equal 'Updated name', @tag.reload.name
  end

  # Prueba de eliminación de etiquetas
  test 'destroy' do
    document_ids = @tag.document_ids
    tag_paths = Document.find(document_ids).map(&:tag_path)
    
    assert tag_paths.any? { |tp| tp.split(/\s##\s/).include?(@tag.to_s) }
    
    assert_difference('Tag.count', -1) { @tag.destroy }
    
    tag_paths = Document.find(document_ids).map(&:tag_path)
    
    assert !tag_paths.any? { |tp| tp.split(/\s##\s/).include?(@tag.to_s) }
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
      count: 255)], @tag.errors[:name]
  end

  test 'update name in related documents' do
    @tag.name = 'Test tag'
    @tag.update_related_documents

    documents_tag_path = @tag.documents.map(&:tag_path).compact.sort
    assert documents_tag_path.all? { |tp| tp.match /Test tag/ }
  end
  
  test 'new name is saved in related documents' do
    documents_tag_path = @tag.documents.map(&:tag_path).compact.sort
    
    assert !documents_tag_path.any? { |tp| tp.match /Updated/ }
    assert @tag.update_attributes(name: 'Updated')

    new_documents_tag_path = @tag.documents.reload.map(&:tag_path).compact.sort
    assert new_documents_tag_path.all? { |tp| tp.match /Updated/ }
  end
  
  test 'update private in related documents' do
    assert !@tag.documents.any?(&:private)
    
    @tag.private = true
    @tag.update_related_documents
    
    assert @tag.documents.all?(&:private)
  end
  
  test 'private is saved in related documents' do
    assert !@tag.documents.any?(&:private)
    
    assert @tag.update_attributes(private: true)
    
    assert @tag.documents.reload.all?(&:private)
  end
  
  test 'private convinations in multi tag document' do
    document = Document.find(documents(:math_notes).id)
    tag_ids = document.tags.map(&:id)

    assert_equal 2, tag_ids.size
    assert !document.private
    assert Tag.find(tag_ids.first).update_attributes(private: true)
    
    # Con solo una etiqueta privada ya se considera privado el documento
    assert document.reload.private
    assert Tag.find(tag_ids.second).update_attributes(private: true)
    
    # Sin cambios, ahora las dos son privadas
    assert document.reload.private
    assert Tag.find(tag_ids.first).update_attributes(private: false)
    
    # Sin cambios, falta que la segunda sea pública
    assert document.reload.private
    assert Tag.find(tag_ids.second).update_attributes(private: false)
    
    # Ahora si no se considera privado el documento
    assert !document.reload.private
  end
end
