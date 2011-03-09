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

  test 'should get new' do
    UserSession.create(users(:administrator))
    get :new
    assert_response :success
    assert_select '#error_body', false
    assert_template 'documents/new'
  end

  test 'should create document' do
    UserSession.create(users(:administrator))
    assert_difference('Document.count') do
      post :create, :document => {
        :code => '0001234',
        :name => 'New Name',
        :pages => '15',
        :description => 'New description',
        :tag_ids => [tags(:books).id, tags(:notes).id],
        :file => fixture_file_upload('/files/test.pdf', 'application/pdf')
      }
    end

    assert_redirected_to documents_path
    assert_equal 2, Document.find_by_code('0001234').tags.count
    # Debe poner 1 ya que cuenta las que tiene efectivamente el PDF
    assert_equal 1, Document.find_by_code('0001234').pages
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
      :description => 'Updated description',
      :file => fixture_file_upload('/files/test.pdf', 'application/pdf')
    }
    assert_redirected_to documents_path
    assert_equal 'Updated name', @document.reload.name
    # Debe poner 1 ya que cuenta las que tiene efectivamente el PDF
    assert_equal 1, Document.find_by_code('003456').pages
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

    get :download, :id => @document.to_param, :style => :original
    assert_redirected_to :action => :index
    assert_equal I18n.t(:'view.documents.non_existent'), flash.notice
  end

  test 'should download document' do
    UserSession.create(users(:administrator))
    put :update, :id => @document.to_param, :document => {
      :file => fixture_file_upload('/files/test.pdf', 'application/pdf')
    }
    assert_redirected_to documents_path

    get :download, :id => @document.to_param, :style => :original
    assert_response :success
    assert_equal File.open(@document.reload.file.path).read, @response.body
  end

  test 'should download document thumb' do
    UserSession.create(users(:administrator))
    put :update, :id => @document.to_param, :document => {
      :file => fixture_file_upload('/files/test.pdf', 'application/pdf')
    }
    assert_redirected_to documents_path

    get :download, :id => @document.to_param, :style => :pdf_thumb
    assert_response :success
    assert_equal File.open(@document.reload.file.path(:pdf_thumb)).read,
      @response.body
  end

  test 'should get autocomplete tag list' do
    UserSession.create(users(:administrator))
    get :autocomplete_for_tag_name, :q => 'o'
    assert_response :success
    assert_select 'li', 2

    get :autocomplete_for_tag_name, :q => 'bo'
    assert_response :success
    assert_select 'li', 1

    get :autocomplete_for_tag_name, :q => 'boxyz'
    assert_response :success
    assert_select 'li', false
  end
end