require 'test_helper'

class TagsTest < ActionDispatch::IntegrationTest
  test 'should destroy a tag' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    assert page.has_css?('div.nav-collapse')

    within 'div.nav-collapse' do
      click_link I18n.t('menu.tags')
    end

    assert_page_has_no_errors!
    assert_equal tags_path, current_path
    assert page.has_css?('table tbody')

    within 'table tbody' do
      assert_difference 'Tag.count', -1 do
        remove_confirm = "$('a[data-confirm]').data('confirm', '').removeAttr('data-confirm')"
        page.execute_script(remove_confirm)
        sleep 0.3
        first(:css, 'a[data-method="delete"]').click
        sleep 0.5
      end
    end
    
    assert_page_has_no_errors!
    assert_equal tags_path, current_path
  end
   
  test 'should create tags into tags' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    assert page.has_css?('div.nav-collapse')

    within 'div.nav-collapse' do
      click_link I18n.t('menu.tags')
    end

    assert_page_has_no_errors!
    assert_equal tags_path, current_path

    within '.form-actions' do
      click_link I18n.t('label.new')
    end

    assert_page_has_no_errors!
    assert_equal new_tag_path, current_path

    fill_in 'tag_name', with: 'Animals'

    assert_difference 'Tag.count' do
      click_button I18n.t('helpers.submit.create', model: Tag.model_name.human)
    end

    assert_page_has_no_errors!
    assert page.has_css?('.alert', text: I18n.t('view.tags.correctly_created'))
    assert_equal tags_path, current_path

    click_link 'Animals'

    assert_page_has_no_errors!

    within '.form-actions' do
      click_link I18n.t('label.new')
    end

    assert_page_has_no_errors!
    assert_equal new_tag_path, current_path

    fill_in 'tag_name', with: 'Mammals'

    assert_difference 'Tag.count'do
      click_button I18n.t('helpers.submit.create', model: Tag.model_name.human)
    end

    assert_page_has_no_errors!
    assert page.has_css?('.alert', text: I18n.t('view.tags.correctly_created'))
  end
end
