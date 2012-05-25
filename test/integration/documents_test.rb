require 'test_helper'

class DocumentsTest < ActionDispatch::IntegrationTest
  fixtures :all
  
  setup do
    Capybara.current_driver = Capybara.javascript_driver # :selenium by default
    Capybara.server_port = '54163'
    Capybara.app_host = "http://localhost:54163"
    page.driver.options[:resynchronize] = true
  end
  
  test 'should create a document' do
    adm_login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    
    visit new_document_path
    assert_page_has_no_errors!
    assert_equal new_document_path, current_path

    within 'form' do
      fill_in Document.human_attribute_name('code'), with: '10'
      fill_in Document.human_attribute_name('name'), with: 'Test'
      select('A4', from: Document.human_attribute_name('media'))
      fill_in Document.human_attribute_name('description'), 
        with: 'Testing upload a pdf'
      file = File.join(Rails.root, 'test', 'fixtures', 'files', 'test.pdf')
      attach_file(Document.human_attribute_name('file'), file)
      fill_in 'autocomplete_tag_tag_NEW_RECORD', with: 'Notes'
      sleep(0.5) #El autocomplete tarda...
      find('#autocomplete_tag_tag_NEW_RECORD').native.send_keys :arrow_down, 
        :arrow_down, :tab
      assert_difference 'Document.count' do
        click_button I18n.t(
          'helpers.submit.create', model: Document.model_name.human
        )
      end
    end  
    assert_page_has_no_errors!
    assert_equal documents_path, current_path
    assert page.has_css?(
      '.alert', text: I18n.t('view.documents.correctly_created')
    )
  end
    
  test 'should delete a document' do
    adm_login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    
    visit documents_path
    assert_page_has_no_errors!
    assert_equal documents_path, current_path

    within 'table tbody' do
      assert_difference "Document.count", -1 do
        find(
          "a[href*=\"/#{documents(:unused_book).id}\"][data-method='delete']"
        ).click
        page.driver.browser.switch_to.alert.accept
        sleep(0.5)
      end
    end

    assert_page_has_no_errors!
    assert_equal documents_path, current_path
  end

  test 'should delete a tag' do
    adm_login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    
    id_mb = documents(:math_book)
    visit edit_document_path(id_mb)
    assert_page_has_no_errors!
    assert_equal edit_document_path(id_mb), current_path

    within 'form' do
      assert_difference "Document.find(id_mb).tags.count", -1 do
        find('[data-event=removeItem]').click
        sleep(0.5) # Se tarda un poquito en quitarlo
        click_button I18n.t(
          'helpers.submit.update', model: Document.model_name.human
        )
        sleep(1) # Se tarda un poco en recargar
      end
    end
      
    assert_page_has_no_errors!
    assert_equal documents_path, current_path
    assert page.has_css?(
      '.alert', text: I18n.t('view.documents.correctly_updated')
    )
  end
end
