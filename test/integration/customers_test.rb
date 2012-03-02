require 'test_helper'

class CustomersTest < ActionDispatch::IntegrationTest
 fixtures :all
  
  setup do
    Capybara.current_driver = Capybara.javascript_driver # :selenium by default
    Capybara.server_port = '54163'
    Capybara.app_host = "http://localhost:54163"
    page.driver.options[:resynchronize] = true
  end
  
  test 'should create a customer' do
    adm_login 
    
    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    
    within '#main_menu' do
      click_link I18n.t('menu.admin')
      within '#submenu_admin' do
        click_link I18n.t('menu.customers')
      end
    end
    
    assert_page_has_no_errors!
    assert_equal customers_path, current_path
    
    within 'nav.links' do
      click_link I18n.t('label.new')
    end
    
    assert_page_has_no_errors!
    assert_equal new_customer_path, current_path
    
    within 'form.new_customer' do
      fill_in Customer.human_attribute_name('name'), with: 'Yoda'
      fill_in Customer.human_attribute_name('lastname'), with: 'Master'
      fill_in Customer.human_attribute_name('identification'), with: '060'
      fill_in Customer.human_attribute_name('email'), with: 'yoda@galactic.com'
      fill_in Customer.human_attribute_name('password'), with: 'lightsaber'
      fill_in Customer.human_attribute_name('password_confirmation'), 
        with: 'lightsaber'
      assert_difference 'Customer.count' do
        click_button I18n.t(
          'helpers.submit.create', model: Customer.model_name.human
        )
      end
    end
    
    assert_page_has_no_errors!
    id = Customer.order('created_at DESC, id DESC').first.id
    assert_equal customer_path(id), current_path
    assert page.has_css?(
      '#notice', text: I18n.t('view.customers.correctly_created')
    )
  end
  
  test 'should deposit to a customer' do
    adm_login
    
    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    
    visit edit_customer_path(customers(:student_without_bonus))
    
    fill_in 'deposit_amount_deposit_customer_deposits_attributes_0_', with: 12.55
    
    assert_difference 'Deposit.count' do
      click_button I18n.t(
        'helpers.submit.update', model: Customer.model_name.human
      )
    end
  end
end
