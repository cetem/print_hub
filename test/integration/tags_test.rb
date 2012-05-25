require 'test_helper'

class TagsTest < ActionDispatch::IntegrationTest
  fixtures :all
  
  setup do
    Capybara.current_driver = Capybara.javascript_driver # :selenium by default
    Capybara.server_port = '54163'
    Capybara.app_host = "http://localhost:54163"
    page.driver.options[:resynchronize] = true
  end
  
  
  test 'should destroy a tag' do
    adm_login 

    assert_equal prints_path, current_path
    assert_page_has_no_errors!

    assert page.has_css?('.nav-collapse')

    within '.nav-collapse' do
      click_link I18n.t('menu.tags')
    end

    assert_equal tags_path, current_path
    assert_page_has_no_errors!
    assert page.has_css?('table')

    within 'table tbody' do
      assert_difference 'Tag.count', -1 do
        find("a[data-method='delete']").click
        page.driver.browser.switch_to.alert.accept
        sleep(0.5)
      end
    end
    
    assert_page_has_no_errors!
    assert_equal tags_path, current_path
  end
   
  test 'should create tags into tags' do
    adm_login

    assert_equal prints_path, current_path
    assert_page_has_no_errors!

    assert page.has_css?('.nav-collapse')

    within '.nav-collapse' do
      click_link I18n.t('menu.tags')
    end

    assert_equal tags_path, current_path
    assert_page_has_no_errors!

    within '.form-actions' do
      click_link I18n.t('label.new')
    end

    assert_equal new_tag_path, current_path
    assert_page_has_no_errors!

    fill_in 'tag_name', with: 'Animals'

    assert_difference 'Tag.count' do
      click_button I18n.t('helpers.submit.create', model: Tag.model_name.human)
    end

    assert page.has_css?('.alert', text: I18n.t('view.tags.correctly_created'))
    assert_equal tags_path, current_path
    assert_page_has_no_errors!

    click_link 'Animals'

    assert_page_has_no_errors!

    within '.form-actions' do
      click_link I18n.t('label.new')
    end

    assert_equal new_tag_path, current_path
    assert_page_has_no_errors!

    fill_in 'tag_name', with: 'Mammals'

    assert_difference 'Tag.count'do
      click_button I18n.t('helpers.submit.create', model: Tag.model_name.human)
    end

    assert_page_has_no_errors!
    assert page.has_css?('.alert', text: I18n.t('view.tags.correctly_created'))
  end
end
