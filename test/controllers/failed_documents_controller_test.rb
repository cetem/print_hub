require 'test_helper'

class FailedDocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @failed_document = failed_documents(:failed_math)
  end

  test "should get index" do
    get failed_documents_url
    assert_response :success
  end

  test "should get new" do
    get new_failed_document_url
    assert_response :success
  end

  test "should create failed_document" do
    assert_difference('FailedDocument.count') do
      post failed_documents_url, { params: { failed_document: {
        name:       @failed_document.name,
        unit_price: @failed_document.unit_price,
        stock:      @failed_document.stock,
        comment:    @failed_document.comment
      } } }
    end

    assert_redirected_to failed_document_url(FailedDocument.last)
  end

  test "should show failed_document" do
    get failed_document_url(@failed_document)
    assert_response :success
  end

  test "should get edit" do
    get edit_failed_document_url(@failed_document)
    assert_response :success
  end

  test "should update failed_document" do
    patch failed_document_url(@failed_document), { params: { failed_document: {
      comment:    @failed_document.comment,
      name:       @failed_document.name,
      unit_price: @failed_document.unit_price,
      stock:      @failed_document.stock
    } } }
    assert_redirected_to failed_document_url(@failed_document)
  end
end
