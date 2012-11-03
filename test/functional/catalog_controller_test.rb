require 'test_helper'

class CatalogControllerTest < ActionController::TestCase
  setup do
    @document = documents(:math_book)
    @request.host = "#{APP_CONFIG['subdomains']['customers']}.printhub.local"

    prepare_document_files
  end
  
  test 'should get index' do
    CustomerSession.create(customers(:student))
    get :index
    assert_response :success
    assert_nil assigns(:documents) # Index with no search give no documents =)
    assert_select '#unexpected_error', false
    assert_template 'catalog/index'
  end

  test 'should get index with tag filter' do
    CustomerSession.create(customers(:student))
    tag = Tag.find(tags(:notes).id)

    get :index, tag_id: tag.to_param
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_equal tag.documents.count, assigns(:documents).size
    assert assigns(:documents).all? { |d| d.tags.include?(tag) }
    assert_select '#unexpected_error', false
    assert_template 'catalog/index'
  end

  test 'should get index with search filter' do
    CustomerSession.create(customers(:student))
    get :index, q: 'Math'
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_equal 2, assigns(:documents).size
    assert assigns(:documents).all? { |d| d.name.match(/math/i) }
    assert_select '#unexpected_error', false
    assert_template 'catalog/index'
  end
  
  test 'should show document' do
    CustomerSession.create(customers(:student))
    get :show, id: @document.to_param
    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'catalog/show'
  end
  
  test 'should not download original document' do
    CustomerSession.create(customers(:student))
    
    assert File.exists?(@document.file.path(:original))
    get :download, id: @document.to_param, style: :original
    assert_redirected_to catalog_url
    assert_equal I18n.t('view.documents.non_existent'), flash.notice
  end
  
  test 'should not download document if no exist' do
    CustomerSession.create(customers(:student))
    
    if File.exists?(@document.file.path(:pdf_thumb))
      FileUtils.rm @document.file.path(:pdf_thumb)
    end
    
    assert !File.exists?(@document.file.path(:pdf_thumb))
    get :download, id: @document.to_param, style: :pdf_thumb
    assert_redirected_to catalog_url
    assert_equal I18n.t('view.documents.non_existent'), flash.notice
  end

  test 'should download document' do
    CustomerSession.create(customers(:student))
    @document.file.reprocess!(:pdf_thumb)
    get :download, id: @document.to_param, style: :pdf_thumb
    assert_response :success
    assert_equal(
      File.open(@document.reload.file.path(:pdf_thumb), encoding: 'ASCII-8BIT').read,
      @response.body
    )
  end
  
  test 'should add document to order' do
    CustomerSession.create(customers(:student))
    assert session[:documents_to_order].blank?
    
    i18n_scope = [:view, :catalog, :remove_from_order]
    
    xhr :post, :add_to_order, id: @document.to_param
    assert_response :success
    assert_match %r{#{I18n.t(:title, scope: i18n_scope)}}, @response.body
    assert session[:documents_to_order].include?(@document.id)
  end
  
  test 'should remove document from next print' do
    CustomerSession.create(customers(:student))
    assert session[:documents_to_order].blank?
    
    session[:documents_to_order] = [@document.id]
    i18n_scope = [:view, :catalog, :add_to_order]
    
    xhr :delete, :remove_from_order, id: @document.to_param
    assert_response :success
    assert_match %r{#{I18n.t(:title, scope: i18n_scope)}},
      @response.body
    assert !session[:documents_to_order].include?(@document.id)
    
    assert session[:documents_to_order].blank?
  end
  
  test 'should add document by code to a new order' do
    CustomerSession.create(customers(:student))
    assert session[:documents_to_order].blank?
    
    get :add_to_order_by_code, id: @document.code
    assert_redirected_to new_order_url
    assert session[:documents_to_order].include?(@document.id)
  end
  
  test 'should not add document by code to a new order if not exists' do
    CustomerSession.create(customers(:student))
    assert session[:documents_to_order].blank?
    
    get :add_to_order_by_code, id: 'wrong_code'
    assert_redirected_to catalog_url
    assert_equal I18n.t('view.documents.non_existent'), flash.notice
    assert session[:documents_to_order].blank?
  end

  test 'should get tags' do
    CustomerSession.create(customers(:student))
    tags = Tag.publicly_visible.where(parent_id: nil).limit(
      (APP_LINES_PER_PAGE / 2).round
    ).with_documents_or_children

    get :tags
    assert_response :success
    assert_not_nil assigns(:tags)
    assert_equal tags.count, assigns(:tags).size
    assert_select '#unexpected_error', false
    assert_template 'catalog/tags'
  end

  test 'should get tag childrens' do
    CustomerSession.create(customers(:student))
    parent = tags(:notes)
    tags = Tag.publicly_visible.where(parent_id: parent.id).limit(
      (APP_LINES_PER_PAGE / 2).round
    )

    assert tags.size > 0

    get :tags, parent_id: parent.to_param
    assert_response :success
    assert_not_nil assigns(:tags)
    assert_equal tags.count, assigns(:tags).size
    assert_select '#unexpected_error', false
    assert_template 'catalog/tags'
  end

  test 'should get document through tag' do
    CustomerSession.create(customers(:student))
    tag = tags(:notes)
    document_with_tag = Document.publicly_visible.with_tag(tag)
  
    get :index, tag_id: tag.to_param
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_equal document_with_tag.count, assigns(:documents).size
    assert_select '#unexpected_error', false
    assert_template 'catalog/index'
  end
end
