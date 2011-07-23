require 'test_helper'

class CatalogControllerTest < ActionController::TestCase
  setup do
    @document = documents(:math_book)
    @request.host = 'facultad.printhub.local'

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
end