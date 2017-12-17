require 'test_helper'

class DocumentsControllerTest < ActionController::TestCase
  setup do
    @document = documents(:math_book)
    @operator = users(:operator)

    UserSession.create(@operator)

    prepare_document_files
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_not_nil assigns(:documents_for_printing)
    # assert_select '#unexpected_error', false
    assert_template 'documents/index'
  end

  test 'should get index with tag filter' do
    tag = tags(:notes)

    get :index, params: { tag_id: tag.to_param }
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_equal tag.documents.count, assigns(:documents).size
    assert assigns(:documents).all? { |d| d.tags.include?(tag) }
    # assert_select '#unexpected_error', false
    assert_template 'documents/index'
  end

  test 'should get index with search filter' do
    get :index, params: { q: 'Math' }
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_equal 2, assigns(:documents).size
    assert assigns(:documents).all? { |d| d.name.match(/math/i) }
    # assert_select '#unexpected_error', false
    assert_template 'documents/index'
  end

  test 'should clear documents for printing' do
    session[:documents_for_printing] = [@document.id]

    get :index, params: { clear_documents_for_printing: true }
    assert_redirected_to action: :index
    assert session[:documents_for_printing].blank?
  end

  test 'should get new' do
    get :new
    assert_response :success
    # assert_select '#unexpected_error', false
    assert_template 'documents/new'
  end

  test 'should create document' do
    assert_difference 'Document.count' do
      # 1 document, 2 document-tags-relation, 2 tags update
      assert_difference 'PaperTrail::Version.count', 5 do
        post :create, params: {
          document: {
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
        }
      end
    end

    assert_redirected_to documents_path
    assert_equal 2, Document.find_by_code('0001234').tags.count
    # Debe poner 1 ya que cuenta las que tiene efectivamente el PDF
    assert_equal 1, Document.find_by_code('0001234').pages
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal @operator.id, PaperTrail::Version.last.whodunnit
  end

  test 'should show document' do
    get :show, params: { id: @document.to_param }
    assert_response :success
    # assert_select '#unexpected_error', false
    assert_template 'documents/show'
  end

  test 'should get edit' do
    get :edit, params: { id: @document.to_param }
    assert_response :success
    # assert_select '#unexpected_error', false
    assert_template 'documents/edit'
  end

  test 'should update document' do
    put :update, params: { id: @document.to_param, document: {
      code: '003456',
      name: 'Updated name',
      stock: '1',
      pages: '15',
      media: PrintJobType::MEDIA_TYPES.values.first,
      enable: '1',
      description: 'Updated description',
      auto_tag_name: 'Some name given in autocomplete'
    } }

    assert_redirected_to documents_path
    assert_equal 'Updated name', @document.reload.name
  end

  test 'should destroy document' do
    document = documents(:unused_book)

    assert_difference('Document.count', -1) do
      delete :destroy, params: { id: document.to_param }
    end

    assert_redirected_to documents_path
  end

  test 'should not destroy document' do
    assert_no_difference('Document.count') do
      delete :destroy, params: { id: @document.to_param }
    end

    assert_redirected_to documents_path
  end

  test 'should get barcode' do
    get :barcode, params: { id: @document.code }
    assert_response :success
    assert_not_nil assigns(:document)
    # assert_select '#unexpected_error', false
    # assert_select 'figcaption', @document.code.to_s
    assert_template 'documents/barcode'
  end

  test 'should get barcode of new document' do
    get :barcode, params: { id: '159321' }
    assert_response :success
    assert_not_nil assigns(:document)
    # assert_select '#unexpected_error', false
    # assert_select 'figcaption', '159321'
    assert_template 'documents/barcode'
  end

  test 'should add document to next print' do
    assert session[:documents_for_printing].blank?

    i18n_scope = [:view, :documents, :remove_from_next_print]

    post :add_to_next_print, params: { id: @document.to_param }, xhr: true
    assert_response :success
    assert_match /#{I18n.t(:title, scope: i18n_scope)}/, @response.body
    assert session[:documents_for_printing].include?(@document.id)
  end

  test 'should remove document from next print' do
    assert session[:documents_for_printing].blank?

    session[:documents_for_printing] = [@document.id]
    i18n_scope = [:view, :documents, :add_to_next_print]

    delete :remove_from_next_print, params: { id: @document.to_param }, xhr: true
    assert_response :success
    assert_match /#{I18n.t(:title, scope: i18n_scope)}/,
                 @response.body
    assert !session[:documents_for_printing].include?(@document.id)

    assert session[:documents_for_printing].blank?
  end

  test 'should get autocomplete tag list' do
    get :autocomplete_for_tag_name, params: { q: 'note' }, format: :json
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, tags.size
    assert tags.all? { |t| t['label'].match /note/i }

    get :autocomplete_for_tag_name, params: { q: 'books' }, format: :json
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, tags.size
    assert tags.all? { |t| t['label'].match /books/i }

    get :autocomplete_for_tag_name, params: { q: 'boxyz' }, format: :json
    assert_response :success

    tags = ActiveSupport::JSON.decode(@response.body)

    assert tags.empty?
  end

  test 'should get index with disabled documents filter' do
    disabled_documents = Document.unscoped.disable.size
    assert disabled_documents > 0
    get :index, params: { disabled_documents: true }
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_equal disabled_documents, assigns(:documents).size
    assert assigns(:documents).all? { |d| d.name.match(/disabled/i) }
    # assert_select '#unexpected_error', false
    assert_template 'documents/index'
  end
end
