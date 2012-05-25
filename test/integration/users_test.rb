require 'test_helper'

class UsersTest < ActionDispatch::IntegrationTest
  fixtures :all
  
  setup do
    Capybara.current_driver = Capybara.javascript_driver # :selenium by default
    Capybara.server_port = '54163'
    Capybara.app_host = "http://localhost:54163"
    page.driver.options[:resynchronize] = true
  end
  
  test 'should create an user' do
    adm_login
    
    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    visit new_user_path
    assert_page_has_no_errors!
    assert_equal new_user_path, current_path
    
    within 'form' do
      fill_in User.human_attribute_name('name'), with: 'Mace'
      fill_in User.human_attribute_name('last_name'), with: 'Windu'
      select( I18n.t('lang.es'), from: 'user_language')
      fill_in User.human_attribute_name('email'), with: 'mace@galactic.com'
      select(
        Cups.show_destinations.detect { |p| p =~ /pdf/i }, 
          from: 'user_default_printer'
      )
      fill_in User.human_attribute_name('username'), with: 'MaceWindu'
      fill_in User.human_attribute_name('password'), with: 'KillSith'
      fill_in User.human_attribute_name('password_confirmation'), 
        with: 'KillSith'
      check 'user_enable'
      assert_difference 'User.count' do
        click_button I18n.t(
          'helpers.submit.create', model: User.model_name.human
        )
      end
    end
    assert_page_has_no_errors!
    assert page.has_css?('.alert', text: I18n.t('view.users.correctly_created'))
  end  
end
