require 'test_helper'

class DocumentsControllerTest < ActionController::TestCase
  setup do
    @document = documents(:math_book)

    prepare_document_files
  end

  test 'should get index' do
    UserSession.create(users(:administrator))
    get :index
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_not_nil assigns(:documents_for_printing)
    assert_select '#unexpected_error', false
    assert_template 'documents/index'
  end

  test 'should get index with tag filter' do
    UserSession.create(users(:administrator))
    tag = Tag.find(tags(:notes).id)

    get :index, tag_id: tag.to_param
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_equal tag.documents.count, assigns(:documents).size
    assert assigns(:documents).all? { |d| d.tags.include?(tag) }
    assert_select '#unexpected_error', false
    assert_template 'documents/index'
  end

  test 'should get index with search filter' do
    UserSession.create(users(:administrator))
    get :index, q: 'Math'
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_equal 2, assigns(:documents).size
    assert assigns(:documents).all? { |d| d.name.match(/math/i) }
    assert_select '#unexpected_error', false
    assert_template 'documents/index'
  end

  test 'should clear documents for printing' do
    UserSession.create(users(:administrator))
    session[:documents_for_printing] = [@document.id]

    get :index, clear_documents_for_printing: true
    assert_redirected_to action: :index
    assert session[:documents_for_printing].blank?
  end

  test 'should get new' do
    UserSession.create(users(:administrator))
    get :new
    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'documents/new'
  end

  test 'should create document' do
    UserSession.create(users(:administrator))
    assert_difference 'Document.count' do
      # 1 document, 2 document-tags-relation, 2 tags update
      assert_difference 'PaperTrail::Version.count', 5 do
        post :create, document: {
          code: '0001234',
          name: 'New Name',
          stock: '1',
          pages: '15',
          media: PrintJobType::MEDIA_TYPES.values.first,
          enable: '1',
          description: 'New description',
          auto_tag_name: 'Some name given in autocomplete',
          tag_ids: [tags(:books).id, tags(:notes).id],
          file: pdf_test_file
        }
      end
    end

    assert_redirected_to documents_path
    assert_equal 2, Document.find_by_code('0001234').tags.count
    # Debe poner 1 ya que cuenta las que tiene efectivamente el PDF
    assert_equal 1, Document.find_by_code('0001234').pages
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal users(:administrator).id, PaperTrail::Version.last.whodunnit
  end

  test 'should show document' do
    UserSession.create(users(:administrator))
    get :show, id: @document.to_param
    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'documents/show'
  end

  test 'should get edit' do
    UserSession.create(users(:administrator))
    get :edit, id: @document.to_param
    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'documents/edit'
  end

  test 'should update document' do
    UserSession.create(users(:administrator))
    put :update, id: @document.to_param, document: {
      code: '003456',
      name: 'Updated name',
      stock: '1',
      pages: '15',
      media: PrintJobType::MEDIA_TYPES.values.first,
      enable: '1',
      description: 'Updated description',
      auto_tag_name: 'Some name given in autocomplete'
    }

    assert_redirected_to documents_path
    assert_equal 'Updated name', @document.reload.name
  end

  test 'should destroy document' do
    document = Document.find(documents(:unused_book).id)

    UserSession.create(users(:administrator))
    assert_difference('Document.count', -1) do
      delete :destroy, id: document.to_param
    end

    assert_redirected_to documents_path
  end

  test 'should not destroy document' do
    UserSession.create(users(:administrator))
    assert_no_difference('Document.count') do
      delete :destroy, id: @document.to_param
    end

    assert_redirected_to documents_path
  end

  test 'should get barcode' do
    UserSession.create(users(:administrator))
    get :barcode, id: @document.code
    assert_response :success
    assert_not_nil assigns(:document)
    assert_select '#unexpected_error', false
    assert_select 'figcaption', @document.code.to_s
    assert_template 'documents/barcode'
  end

  test 'should get barcode of new document' do
    UserSession.create(users(:administrator))
    get :barcode, id: '159321'
    assert_response :success
    assert_not_nil assigns(:document)
    assert_select '#unexpected_error', false
    assert_select 'figcaption', '159321'
    assert_template 'documents/barcode'
  end

  test 'should add document to next print' do
    UserSession.create(users(:administrator))
    assert session[:documents_for_printing].blank?

    i18n_scope = [:view, :documents, :remove_from_next_print]

    xhr :post, :add_to_next_print, id: @document.to_param
    assert_response :success
    assert_match %r{#{I18n.t(:title, scope: i18n_scope)}}, @response.body
    assert session[:documents_for_printing].include?(@document.id)
  end

  test 'should remove document from next print' do
    UserSession.create(users(:administrator))
    assert session[:documents_for_printing].blank?

    session[:documents_for_printing] = [@document.id]
    i18n_scope = [:view, :documents, :add_to_next_print]

    xhr :delete, :remove_from_next_print, id: @document.to_param
    assert_response :success
    assert_match %r{#{I18n.t(:title, scope: i18n_scope)}},
      @response.body
    assert !session[:documents_for_printing].include?(@document.id)

    assert session[:documents_for_printing].blank?
  end

  test 'should get autocomplete tag list' do
    UserSession.create(users(:administrator))
    get :autocomplete_for_tag_name, format: :json, q: 'note'
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, tags.size
    assert tags.all? { |t| t['label'].match /note/i }

    get :autocomplete_for_tag_name, format: :json, q: 'books'
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, tags.size
    assert tags.all? { |t| t['label'].match /books/i }

    get :autocomplete_for_tag_name, format: :json, q: 'boxyz'
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert tags.empty?
  end

  test 'should get index with disabled documents filter' do
    UserSession.create(users(:administrator))
    disabled_documents = Document.unscoped.disable.size
    assert disabled_documents > 0
    get :index, disabled_documents: true
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_equal disabled_documents, assigns(:documents).size
    assert assigns(:documents).all? { |d| d.name.match(/disabled/i) }
    assert_select '#unexpected_error', false
    assert_template 'documents/index'
  end
end
