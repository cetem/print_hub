require 'test_helper'

class CatalogControllerTest < ActionController::TestCase
  setup do
    @document = documents(:math_book)
    @request.host = "#{APP_CONFIG['subdomains']['customers']}.printhub.local"

    CustomerSession.create(customers(:student))

    prepare_document_files
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_nil assigns(:documents) # Index with no search give no documents =)
    assert_select '#unexpected_error', false
    assert_template 'catalog/index'
  end

  test 'should get index with tag filter' do
    tag = tags(:notes)

    get :index, tag_id: tag.to_param
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_equal tag.documents.count, assigns(:documents).size
    assert assigns(:documents).all? { |d| d.tags.include?(tag) }
    assert_select '#unexpected_error', false
    assert_template 'catalog/index'
  end

  test 'should get index with search filter' do
    get :index, q: 'Math'
    assert_response :success
    assert_not_nil assigns(:documents)
    assert_equal 2, assigns(:documents).size
    assert assigns(:documents).all? { |d| d.name.match(/math/i) }
    assert_select '#unexpected_error', false
    assert_template 'catalog/index'
  end

  test 'should show document' do
    get :show, id: @document.to_param
    assert_response :success
    assert_select '#unexpected_error', false
    assert_template 'catalog/show'
  end

  test 'should add document to order' do
    assert session[:documents_to_order].blank?

    i18n_scope = [:view, :catalog, :remove_from_order]

    xhr :post, :add_to_order, id: @document.to_param
    assert_response :success
    assert_match /#{I18n.t(:title, scope: i18n_scope)}/, @response.body
    assert session[:documents_to_order].include?(@document.id)
  end

  test 'should remove document from next print' do
    assert session[:documents_to_order].blank?

    session[:documents_to_order] = [@document.id]
    i18n_scope = [:view, :catalog, :add_to_order]

    xhr :delete, :remove_from_order, id: @document.to_param
    assert_response :success
    assert_match /#{I18n.t(:title, scope: i18n_scope)}/,
                 @response.body
    assert !session[:documents_to_order].include?(@document.id)

    assert session[:documents_to_order].blank?
  end

  test 'should add document by code to a new order' do
    assert session[:documents_to_order].blank?

    get :add_to_order_by_code, id: @document.code
    assert_redirected_to new_order_url
    assert session[:documents_to_order].include?(@document.id)
  end

  test 'should not add document by code to a new order if not exists' do
    assert session[:documents_to_order].blank?

    get :add_to_order_by_code, id: 'wrong_code'
    assert_redirected_to catalog_url
    assert_equal I18n.t('view.documents.non_existent'), flash.notice
    assert session[:documents_to_order].blank?
  end

  test 'should get tags' do
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
