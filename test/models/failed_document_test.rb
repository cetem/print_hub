require 'test_helper'

class FailedDocumentTest < ActiveSupport::TestCase
  def setup
    @failed_document = FailedDocument.find failed_documents(:failed_math).id
  end

  test 'create' do
    assert_difference 'FailedDocument.count' do
      @failed_document = FailedDocument.create(
        name:        documents(:math_notes).to_s,
        unit_price:  '5.5',
        stock:       3,
        comment:     'Not really sharp'
      )
    end
  end

  test 'update' do
    assert_no_difference 'FailedDocument.count' do
      assert @failed_document.update(name: 'Updated name'),
             @failed_document.errors.full_messages.join('; ')
    end

    assert_equal 'Updated name', @failed_document.reload.name
  end

  test 'validates blank attributes' do
    @failed_document.name       = '  '
    @failed_document.unit_price = '  '
    @failed_document.stock      = '  '

    assert @failed_document.invalid?
    assert_equal [error_message_from_model(@failed_document, :name, :blank)],
                 @failed_document.errors[:name]
    assert_equal [error_message_from_model(@failed_document, :unit_price, :not_a_number)],
                 @failed_document.errors[:unit_price]
    assert_equal [error_message_from_model(@failed_document, :stock, :not_a_number)],
                 @failed_document.errors[:stock]
  end

  test 'validates formatted attributes' do
    @failed_document.unit_price = '?xx'
    @failed_document.stock = '?xx'

    assert @failed_document.invalid?
    assert_equal [error_message_from_model(@failed_document, :unit_price, :not_a_number)],
                 @failed_document.errors[:unit_price]
    assert_equal [error_message_from_model(@failed_document, :stock, :not_a_number)],
                 @failed_document.errors[:stock]

    @failed_document.unit_price = '-0.01'
    @failed_document.stock = '-1'

    assert @failed_document.invalid?
    assert_equal [error_message_from_model(@failed_document, :unit_price,
                                           :greater_than, count: 0)], @failed_document.errors[:unit_price]
    assert_equal [error_message_from_model(@failed_document, :stock,
                                           :greater_than_or_equal_to, count: 0)], @failed_document.errors[:stock]

    @failed_document.stock = '32768'

    assert @failed_document.invalid?
    assert_equal [error_message_from_model(@failed_document, :stock,
                                           :less_than_or_equal_to, count: 32767)], @failed_document.errors[:stock]

    @failed_document.stock = '3.5'

    assert @failed_document.invalid?
    assert_equal [error_message_from_model(@failed_document, :stock, :not_an_integer)],
                 @failed_document.errors[:stock]
  end

  test 'full text search' do
    failed_documents = FailedDocument.full_text(['math'])

    assert_equal 1, failed_documents.size
    assert_equal '[1] Math', failed_documents.first.name

    failed_documents = FailedDocument.full_text(['1'])

    assert_equal 1, failed_documents.size
    assert_equal '[1] Math', failed_documents.first.name
  end
end
