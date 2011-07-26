require 'test_helper'

class CatalogControllerTest < ActionController::TestCase
  setup do
    @document = documents(:math_book)
    @request.host = "#{CUSTOMER_SUBDOMAIN}.printhub.local"

    prepare_document_files
  end
  
  test 'should get index' do
    CustomerSession.create(customers(:student))
    get :index
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_select '#error_body', false
    assert_template 'catalog/index'
  end

  test 'should get index with tag filter' do
    CustomerSession.create(customers(:student))
    tag = Tag.find(tags(:notes).id)

    get :index, :tag_id => tag.to_param
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_equal tag.documents.count, assigns(:documents).size
    assert assigns(:documents).all? { |d| d.tags.include?(tag) }
    assert_select '#error_body', false
    assert_template 'catalog/index'
  end

  test 'should get index with search filter' do
    Document.all.each do |d|
      d.update_attributes!(:tag_path => d.tags.map(&:to_s).join(' ## '))
    end

    CustomerSession.create(customers(:student))
    get :index, :q => 'Math'
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_equal 2, assigns(:documents).size
    assert assigns(:documents).all? { |d| d.name.match(/math/i) }
    assert_select '#error_body', false
    assert_template 'catalog/index'
  end
  
  test 'should show document' do
    CustomerSession.create(customers(:student))
    get :show, :id => @document.to_param
    assert_response :success
    assert_select '#error_body', false
    assert_template 'catalog/show'
  end
  
  test 'should not download original document' do
    CustomerSession.create(customers(:student))
    
    assert File.exists?(@document.file.path(:original))
    get :download, :id => @document.to_param, :style => :original
    assert_redirected_to catalog_url
    assert_equal I18n.t(:'view.documents.non_existent'), flash.notice
  end
  
  test 'should not download document if no exist' do
    CustomerSession.create(customers(:student))
    
    if File.exists?(@document.file.path(:pdf_thumb))
      FileUtils.rm @document.file.path(:pdf_thumb)
    end
    
    assert !File.exists?(@document.file.path(:pdf_thumb))
    get :download, :id => @document.to_param, :style => :pdf_thumb
    assert_redirected_to catalog_url
    assert_equal I18n.t(:'view.documents.non_existent'), flash.notice
  end

  test 'should download document' do
    CustomerSession.create(customers(:student))
    @document.file.reprocess!(:pdf_thumb)
    get :download, :id => @document.to_param, :style => :pdf_thumb
    assert_response :success
    assert_equal(
      File.open(@document.reload.file.path(:pdf_thumb), :encoding => 'ASCII-8BIT').read,
      @response.body
    )
  end
  
  test 'should add document to order' do
    CustomerSession.create(customers(:student))
    assert session[:documents_to_order].blank?
    
    i18n_scope = [:view, :catalog, :remove_from_order]
    
    xhr :post, :add_to_order, :id => @document.to_param
    assert_response :success
    assert_match %r{#{I18n.t(:link, :scope => i18n_scope)}}, @response.body
    assert session[:documents_to_order].include?(@document.id)
  end
  
  test 'should remove document from next print' do
    CustomerSession.create(customers(:student))
    assert session[:documents_to_order].blank?
    
    session[:documents_to_order] = [@document.id]
    i18n_scope = [:view, :catalog, :add_to_order]
    
    xhr :delete, :remove_from_order, :id => @document.to_param
    assert_response :success
    assert_match %r{#{I18n.t(:link, :scope => i18n_scope)}},
      @response.body
    assert !session[:documents_to_order].include?(@document.id)
    
    assert session[:documents_to_order].blank?
  end
end