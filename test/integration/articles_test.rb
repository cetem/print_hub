require 'test_helper'

class ArticlesTest < ActionDispatch::IntegrationTest
  test 'should create an article' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    visit new_article_path

    assert_page_has_no_errors!
    assert_equal new_article_path, current_path

    within 'form' do
      fill_in Article.human_attribute_name('code'), with: '007'
      fill_in Article.human_attribute_name('name'), with: 'Laminate'
      fill_in Article.human_attribute_name('price'), with: '1.50'
      fill_in Article.human_attribute_name('description'),
              with: 'Laminate a carnet or anything'

      assert_difference 'Article.count' do
        click_button I18n.t(
          'helpers.submit.create', model: Article.model_name.human
        )
      end
    end
  end

  test 'should delete an article' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    visit articles_path

    assert_page_has_no_errors!
    assert_equal articles_path, current_path

    within 'table tbody' do
      assert_difference 'Article.count', -1 do
        accept_alert do
          all("a[data-method='delete']")[1].click # El 1ro esta usado
        end
      end
    end

    assert_page_has_no_errors!
    assert_equal articles_path, current_path
  end
end
