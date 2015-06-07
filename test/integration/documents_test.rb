require 'test_helper'

class DocumentsTest < ActionDispatch::IntegrationTest
  test 'should create a document' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    visit new_document_path
    assert_page_has_no_errors!
    assert_equal new_document_path, current_path
    draft_tag = tags(:draft_note)

    within 'form' do
      fill_in Document.human_attribute_name('code'), with: '10'
      fill_in Document.human_attribute_name('name'), with: 'Test'
      select('A4', from: Document.human_attribute_name('media'))
      fill_in Document.human_attribute_name('description'),
              with: 'Testing upload a pdf'
      file = File.join(Rails.root, 'test', 'fixtures', 'files', 'test.pdf')
      attach_file(Document.human_attribute_name('file'), file)
      fill_in 'autocomplete_tag_tag_NEW_RECORD', with: draft_tag.name
      sleep 2
      assert page.has_xpath?("//li[@class='ui-menu-item']", visible: true)
      find('#autocomplete_tag_tag_NEW_RECORD').native.send_keys :arrow_down, :tab

      assert_difference 'Document.count' do
        assert_difference 'draft_tag.reload.documents_count' do
          click_button I18n.t(
            'helpers.submit.create', model: Document.model_name.human
          )
        end
      end
    end

    assert_page_has_no_errors!
    assert_equal documents_path, current_path
    assert page.has_css?(
      '.alert', text: I18n.t('view.documents.correctly_created')
    )
  end

  test 'should delete a document' do
    login

    visit documents_path
    assert_page_has_no_errors!
    assert_equal documents_path, current_path

    unused_book = documents(:unused_book)
    tag = unused_book.tags.first

    within 'table tbody' do
      assert_difference ['Document.count', 'tag.reload.documents_count'], -1 do
        find("a[href*=\"/#{unused_book.id}\"][data-method='delete']").click
        sleep(1)
        page.driver.browser.switch_to.alert.accept
        sleep(1)
      end
    end

    assert_page_has_no_errors!
    assert_equal documents_path, current_path
  end

  test 'should delete a tag' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    math_book = documents(:math_book)
    visit edit_document_path(math_book)
    assert_page_has_no_errors!
    assert_equal edit_document_path(math_book), current_path
    first_tag = math_book.tags.first

    within 'form' do
      assert_difference 'Document.find(math_book).tags.count', -1 do
        assert_difference 'first_tag.reload.documents_count', -1 do
          within "div#tag_#{first_tag.id}" do
            first(:css, '[data-event=removeItem]').click
            sleep 1
          end

          click_button I18n.t(
            'helpers.submit.update', model: Document.model_name.human
          )
        end
      end
    end

    assert_page_has_no_errors!
    assert_equal documents_path, current_path
    assert page.has_css?(
      '.alert', text: I18n.t('view.documents.correctly_updated')
    )
  end
end
