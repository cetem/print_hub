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
    assert_select '#error_body', false
    assert_template 'documents/index'
  end

  test 'should get index with tag filter' do
    UserSession.create(users(:administrator))
    tag = Tag.find(tags(:notes).id)

    get :index, :tag_id => tag.to_param
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_equal tag.documents.count, assigns(:documents).size
    assert assigns(:documents).all? { |d| d.tags.include?(tag) }
    assert_select '#error_body', false
    assert_template 'documents/index'
  end

  test 'should get index with search filter' do
    Document.all.each do |d|
      d.update_attributes!(:tag_path => d.tags.map(&:to_s).join(' ## '))
    end

    UserSession.create(users(:administrator))
    get :index, :q => 'Math'
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_equal 2, assigns(:documents).size
    assert assigns(:documents).all? { |d| d.name.match(/math/i) }
    assert_select '#error_body', false
    assert_template 'documents/index'
  end
  
  test 'should clear documents for printing' do
    UserSession.create(users(:administrator))
    session[:documents_for_printing] = [@document.id]
    
    get :index, :clear_documents_for_printing => true
    assert_redirected_to :action => :index
    assert session[:documents_for_printing].blank?
  end

  test 'should get new' do
    UserSession.create(users(:administrator))
    get :new
    assert_response :success
    assert_select '#error_body', false
    assert_template 'documents/new'
  end

  test 'should create document' do
    UserSession.create(users(:administrator))
    assert_difference ['Document.count', 'Version.count'] do
      post :create, :document => {
        :code => '0001234',
        :name => 'New Name',
        :pages => '15',
        :media => Document::MEDIA_TYPES.values.first,
        :enable => '1',
        :description => 'New description',
        :auto_tag_name => 'Some name given in autocomplete',
        :tag_ids => [tags(:books).id, tags(:notes).id],
        :file => fixture_file_upload('/files/test.pdf', 'application/pdf')
      }
    end

    assert_redirected_to documents_path
    assert_equal 2, Document.find_by_code('0001234').tags.count
    # Debe poner 1 ya que cuenta las que tiene efectivamente el PDF
    assert_equal 1, Document.find_by_code('0001234').pages
    # Prueba básica para "asegurar" el funcionamiento del versionado
    assert_equal users(:administrator).id, Version.last.whodunnit
  end

  test 'should show document' do
    UserSession.create(users(:administrator))
    get :show, :id => @document.to_param
    assert_response :success
    assert_select '#error_body', false
    assert_template 'documents/show'
  end

  test 'should get edit' do
    UserSession.create(users(:administrator))
    get :edit, :id => @document.to_param
    assert_response :success
    assert_select '#error_body', false
    assert_template 'documents/edit'
  end

  test 'should update document' do
    UserSession.create(users(:administrator))
    put :update, :id => @document.to_param, :document => {
      :code => '003456',
      :name => 'Updated name',
      :pages => '15',
      :media => Document::MEDIA_TYPES.values.first,
      :enable => '1',
      :description => 'Updated description',
      :auto_tag_name => 'Some name given in autocomplete'
    }
    assert_redirected_to documents_path
    assert_equal 'Updated name', @document.reload.name
  end

  test 'should destroy document' do
    document = Document.find(documents(:unused_book).id)

    UserSession.create(users(:administrator))
    assert_difference('Document.count', -1) do
      delete :destroy, :id => document.to_param
    end

    assert_redirected_to documents_path
  end

  test 'should not destroy document' do
    UserSession.create(users(:administrator))
    assert_no_difference('Document.count') do
      delete :destroy, :id => @document.to_param
    end

    assert_redirected_to documents_path
  end

  test 'should not download document' do
    UserSession.create(users(:administrator))
    FileUtils.rm @document.file.path if File.exists?(@document.file.path)

    assert !File.exists?(@document.file.path)
    get :download, :id => @document.to_param, :style => :original
    assert_redirected_to :action => :index
    assert_equal I18n.t(:'view.documents.non_existent'), flash.notice
  end

  test 'should download document' do
    UserSession.create(users(:administrator))
    get :download, :id => @document.to_param, :style => :original
    assert_response :success
    assert_equal File.open(@document.reload.file.path).read, @response.body
  end
  
  test 'should add document to next print' do
    UserSession.create(users(:administrator))
    assert session[:documents_for_printing].blank?
    
    i18n_scope = [:view, :documents, :remove_from_next_print]
    
    xhr :post, :add_to_next_print, :id => @document.to_param
    assert_response :success
    assert_match %r{#{I18n.t(:link, :scope => i18n_scope)}}, @response.body
    assert session[:documents_for_printing].include?(@document.id)
  end
  
  test 'should remove document from next print' do
    UserSession.create(users(:administrator))
    assert session[:documents_for_printing].blank?
    
    session[:documents_for_printing] = [@document.id]
    i18n_scope = [:view, :documents, :add_to_next_print]
    
    xhr :delete, :remove_from_next_print, :id => @document.to_param
    assert_response :success
    assert_match %r{#{I18n.t(:link, :scope => i18n_scope)}},
      @response.body
    assert !session[:documents_for_printing].include?(@document.id)
    
    assert session[:documents_for_printing].blank?
  end

  test 'should get autocomplete tag list' do
    UserSession.create(users(:administrator))
    get :autocomplete_for_tag_name, :q => 'note'
    assert_response :success
    
    tags = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal 2, tags.size
    assert tags.all? { |t| t['label'].match /note/i }

    get :autocomplete_for_tag_name, :q => 'books'
    assert_response :success
    
    tags = ActiveSupport::JSON.decode(@response.body)
    
    assert_equal 1, tags.size
    assert tags.all? { |t| t['label'].match /books/i }

    get :autocomplete_for_tag_name, :q => 'boxyz'
    assert_response :success
    
    tags = ActiveSupport::JSON.decode(@response.body)
    
    assert tags.empty?
  end
end