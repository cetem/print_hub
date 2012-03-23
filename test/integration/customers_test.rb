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
    
    id = Customer.order('updated_at DESC').first.id
    assert_page_has_no_errors!
    assert_equal customer_path(id), current_path
  end
  
  test 'should probe the nested delete in deposits' do
    adm_login
    
    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    
    visit edit_customer_path(customers(:student))
    
    assert_page_has_no_errors!
    assert_equal(
      edit_customer_path(customers(:student)), current_path
    )
    
    deposit = "//input[starts-with(@id,'deposit_amount_')]"
    
    assert_difference "all(:xpath, deposit).size" do
      click_link I18n.t('view.customers.add_deposit')
    end
    
    assert_difference "all(:xpath, deposit).size", -1 do
      find('[data-event=removeItem]').click
      sleep 0.5 # Sino, sigue siendo el mismo nº de antes
    end
  end
  
  test 'should show the bonuses' do
    adm_login
    
    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    
    visit edit_customer_path(customers(:student_without_bonus))
    
    assert_page_has_no_errors!
    assert_equal(
      edit_customer_path(customers(:student_without_bonus)), current_path
    )
    
    assert !find('#bonuses_section').visible?
    click_link I18n.t('view.customers.show_bonuses')
    assert find('#bonuses_section').visible?
  end

  test 'should pay a month debt' do
    adm_login
    
    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    
    visit customer_path(customers(:student))

    id = customers(:student).id
    assert_page_has_no_errors!
    assert_equal customer_path(id), current_path
    
    href = find_link(I18n.t('view.customers.to_pay_prints.month_to_pay'))[:href]
    click_link I18n.t('view.customers.to_pay_prints.month_to_pay')

    href = href.match(/\?date\=(\S+)/)[1]
    current_page = current_url.match(/\:54163(\S+)/)[1]

    assert_page_has_no_errors!
    assert_equal customer_path(id, date: href ), current_page


    assert_difference "Customer.find(#{id}).months_to_pay.count", -1 do
      find('#pay_month_debt').click
    end
    
    assert_page_has_no_errors!
  end

  test 'should pay total debt' do
    adm_login
    
    assert_page_has_no_errors!
    assert_equal prints_path, current_path
    
    visit customer_path(customers(:student))

    assert_page_has_no_errors!
    assert_equal customer_path(customers(:student)), current_path

    id = customers(:student).id
    assert_not_equal Customer.find(id).prints.pay_later.count, 0
    find('#pay_off_debt').click
    assert_equal Customer.find(id).prints.pay_later.count, 0
    assert_page_has_no_errors!
  end
end