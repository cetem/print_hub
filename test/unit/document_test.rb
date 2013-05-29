require 'test_helper'

# Clase para probar el modelo "Document"
class DocumentTest < ActiveSupport::TestCase
  fixtures :documents

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @document = Document.find documents(:math_book).id
    
    prepare_document_files
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'find' do
    assert_kind_of Document, @document
    assert_equal documents(:math_book).code, @document.code
    assert_equal documents(:math_book).name, @document.name
    assert_equal documents(:math_book).stock, @document.stock
    assert_equal documents(:math_book).pages, @document.pages
    assert_equal documents(:math_book).media, @document.media
    assert_equal documents(:math_book).enable, @document.enable
    assert_equal documents(:math_book).tag_path, @document.tag_path
    assert_equal documents(:math_book).description, @document.description
  end

  # Prueba la creación de un documento
  test 'create' do
    assert_difference 'Document.count' do
      file = Rack::Test::UploadedFile.new(
        File.join(Rails.root, 'test', 'fixtures', 'files', 'test.pdf'),
        'application/pdf'
      )

      @document = Document.new({
        code: '00001234',
        name: 'New name',
        stock: 1,
        pages: 5,
        media: PrintJobType::MEDIA_TYPES.values.first,
        description: 'New description',
        enable: true,
        tag_ids: [tags(:books).id, tags(:notes).id],
        file: file
      })

      assert @document.save
    end

    assert_equal 2, @document.tags.count
    assert_equal 1, @document.pages

    thumbs_dir = Pathname.new(@document.file.path).dirname
    # PDF original y 2 miniaturas
    assert_equal 3, thumbs_dir.entries.reject(&:directory?).size
    # Asegurar que las 2 miniaturas son imágenes y no están vacías
    assert_equal 2,
      thumbs_dir.entries.select { |f| f.extname == '.png' && !f.zero? }.size
    
    # Asegurar la "limpieza" del directorio
    Pathname.new(@document.file.path).dirname.rmtree
  end

  # Prueba la creación de un documento con múltiples páginas
  test 'create a multipage document' do
    assert_difference 'Document.count' do
      @document = Document.new({
        code: '00001234',
        name: 'New name',
        stock: 1,
        pages: 1,
        media: PrintJobType::MEDIA_TYPES.values.first,
        enable: true,
        description: 'New description',
        tag_ids: [tags(:books).id, tags(:notes).id]
      })

      @document.file = Rack::Test::UploadedFile.new(
        File.join(Rails.root, 'test', 'fixtures', 'files', 'multipage_test.pdf'),
        'application/pdf'
      )
      assert @document.save
    end

    assert_equal 2, @document.tags.count
    assert_equal 3, @document.pages

    thumbs_dir = Pathname.new(@document.file.path).dirname
    # PDF original y 6 miniaturas
    assert_equal 7, thumbs_dir.entries.reject(&:directory?).size
    # Asegurar que las 6 miniaturas son imágenes y no están vacías
    assert_equal 6,
      thumbs_dir.entries.select { |f| f.extname == '.png' && !f.zero? }.size
    
    # Asegurar la "limpieza" del directorio
    Pathname.new(@document.file.path).dirname.rmtree
  end

  # Prueba de actualización de un documento
  test 'update' do
    assert_no_difference 'Document.count' do
      assert @document.update_attributes(name: 'Updated name'),
        @document.errors.full_messages.join('; ')
    end

    assert_equal 'Updated name', @document.reload.name
  end

  test 'can update with diferent pdfs' do
    file = Rack::Test::UploadedFile.new(
      File.join(Rails.root, 'test', 'fixtures', 'files', 'multipage_test.pdf'),
      'application/pdf'
    )

    # Asegurar la "limpieza" del directorio
    thumbs_dir = Pathname.new(@document.file.path).dirname.rmtree

    assert_no_difference 'Document.count' do
      assert @document.update_attributes(file: file),
        @document.errors.full_messages.join('; ')
    end

    assert_equal 3, @document.reload.pages
    thumbs_dir = Pathname.new(@document.file.path).dirname
    # PDF original y 6 miniaturas
    assert_equal 7, thumbs_dir.entries.reject(&:directory?).size

    file = Rack::Test::UploadedFile.new(
      File.join(Rails.root, 'test', 'fixtures', 'files', 'test.pdf'),
      'application/pdf'
    )

    assert_no_difference 'Document.count' do
      assert @document.update_attributes(file: file),
        @document.errors.full_messages.join('; ')
    end

    assert_equal 1, @document.reload.pages
    # PDF original y 2 miniaturas
    assert_equal 3, thumbs_dir.entries.reject(&:directory?).size
  end

  # Prueba de eliminación de documentos
  test 'destroy' do
    document = Document.find(documents(:unused_book).id)

    assert_difference('Document.count', -1) { document.destroy }
  end

  # Prueba de eliminación de documentos
  test 'not destroy with related print jobs' do
    assert_no_difference('Document.count') { @document.destroy }
  end

  test 'disable a document' do
    assert_difference('Document.count', -1) do
      @document.update_attributes(enable: false)
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @document.code = '  '
    @document.name = '  '
    @document.media = '  '
    @document.pages = nil

    assert @document.invalid?
    assert_equal 4, @document.errors.count
    assert_equal [error_message_from_model(@document, :code, :blank)],
      @document.errors[:code]
    assert_equal [error_message_from_model(@document, :name, :blank)],
      @document.errors[:name]
    assert_equal [error_message_from_model(@document, :media, :blank)],
      @document.errors[:media]
    assert_equal [error_message_from_model(@document, :pages, :blank)],
      @document.errors[:pages]
  end

  test 'validate not blank file' do
    @document = Document.new({
        code: '00001234',
        name: 'New name',
        stock: 1,
        pages: 5,
        media: PrintJobType::MEDIA_TYPES.values.first,
        description: 'New description',
        enable: true,
        tag_ids: [tags(:books).id, tags(:notes).id],
      })

    assert @document.invalid?
    assert_equal 1, @document.errors.size
    assert_equal [error_message_from_model(@document, :file, :blank)],
      @document.errors[:file]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @document.code = documents(:math_notes).code
    assert @document.invalid?
    assert_equal 1, @document.errors.count
    assert_equal [error_message_from_model(@document, :code, :taken)],
      @document.errors[:code]

    @document.enable = false
    assert @document.valid?
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @document.name = 'abcde' * 52
    @document.media = 'abcde' * 52
    assert @document.invalid?
    assert_equal 3, @document.errors.count
    assert_equal [error_message_from_model(@document, :name, :too_long,
      count: 255)], @document.errors[:name]
    assert_equal [error_message_from_model(@document, :media, :too_long,
      count: 255), error_message_from_model(@document, :media,
      :inclusion)].sort, @document.errors[:media].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @document.media = 'invalid'
    assert @document.invalid?
    assert_equal 1, @document.errors.count
    assert_equal [error_message_from_model(@document, :media, :inclusion)],
      @document.errors[:media]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formatted attributes' do
    @document.pages = '?xx'
    @document.code = '?xx'
    @document.stock = '?xx'
    assert @document.invalid?
    assert_equal 3, @document.errors.count
    assert_equal [error_message_from_model(@document, :pages, :not_a_number)],
      @document.errors[:pages]
    assert_equal [error_message_from_model(@document, :code, :not_a_number)],
      @document.errors[:code]
    assert_equal [error_message_from_model(@document, :stock, :not_a_number)],
      @document.errors[:stock]

    @document.pages = '41.23'
    @document.code = '41.23'
    @document.stock = '41.23'
    assert @document.invalid?
    assert_equal 3, @document.errors.count
    assert_equal [error_message_from_model(@document, :pages, :not_an_integer)],
      @document.errors[:pages]
    assert_equal [error_message_from_model(@document, :code, :not_an_integer)],
      @document.errors[:code]
    assert_equal [error_message_from_model(@document, :stock, :not_an_integer)],
      @document.errors[:stock]

    @document.pages = '0'
    @document.code = '0'
    @document.stock = '-1'
    assert @document.invalid?
    assert_equal 3, @document.errors.count
    assert_equal [error_message_from_model(@document, :pages, :greater_than,
        count: 0)], @document.errors[:pages]
    assert_equal [error_message_from_model(@document, :code, :greater_than,
        count: 0)], @document.errors[:code]
    assert_equal [
      error_message_from_model(
        @document, :stock, :greater_than_or_equal_to, count: 0
      )
    ], @document.errors[:stock]
    
    @document.pages = '2147483648'
    @document.code = '2147483648'
    @document.stock = '2147483648'
    assert @document.invalid?
    assert_equal 3, @document.errors.count
    assert_equal [
      error_message_from_model(@document, :pages, :less_than, count: 2147483648)
    ], @document.errors[:pages]
    assert_equal [
      error_message_from_model(@document, :code, :less_than, count: 2147483648)
    ], @document.errors[:code]
    assert_equal [
      error_message_from_model(@document, :stock, :less_than, count: 2147483648)
    ], @document.errors[:stock]
  end

  test 'update tag path' do
    original_path = @document.update_tag_path

    assert_difference '@document.tags.count' do
      @document.tags << Tag.find(tags(:draft_note).id)
    end

    assert @document.save
    assert_not_equal original_path, @document.tag_path
  end
  
  test 'use stock' do
    assert_equal 5, @document.use_stock(5)
    assert_equal 0, @document.stock
    
    @document.stock = 10
    
    assert_equal 0, @document.use_stock(8)
    assert_equal 2, @document.stock
    assert_equal 4, @document.use_stock(6)
    assert_equal 0, @document.stock
  end

  test 'update tags documents count updating' do
    @tag = tags(:notes)

    assert_difference '@tag.reload.documents_count' do
      @document.tags << @tag
      assert @document.save
    end
    
    assert_difference '@tag.reload.documents_count', -1 do
      @document.tag_ids = nil
      assert @document.save
    end
  end

  test 'update tags documents count on delete' do
    @document = documents(:unused_book)
    @tag = @document.tags.first

    assert_difference '@tag.reload.documents_count', -1 do
      assert @document.destroy
    end
  end
  
  test 'full text search' do
    documents = Document.full_text(['unused'])
    
    assert_equal 1, documents.size
    assert_equal 'Unused Book', documents.first.name
    
    documents = Document.full_text(['2'])
    
    assert_equal 1, documents.size
    assert_equal 2, documents.first.code
  end
end
