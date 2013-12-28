require 'test_helper'

class CustomersTest < ActionDispatch::IntegrationTest
  test 'should create a customer' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    within '.nav-collapse' do
      click_link I18n.t('menu.admin')
      within '.dropdown-menu' do
        click_link I18n.t('menu.customers')
      end
    end

    assert_page_has_no_errors!
    assert_equal customers_path, current_path

    within '.form-actions' do
      click_link I18n.t('label.new')
    end

    assert_page_has_no_errors!
    assert_equal new_customer_path, current_path

    within 'form' do
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
    id = Customer.order('id DESC').first.id
    assert_equal customer_path(id), current_path
    assert page.has_css?(
      '.alert', text: I18n.t('view.customers.correctly_created')
    )
  end

  test 'should create a customer with checking account' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    within '.nav-collapse' do
      click_link I18n.t('menu.admin')
      within '.dropdown-menu' do
        click_link I18n.t('menu.customers')
      end
    end

    assert_page_has_no_errors!
    assert_equal customers_path, current_path

    within '.form-actions' do
      click_link I18n.t('label.new')
    end

    assert_page_has_no_errors!
    assert_equal new_customer_path, current_path

    within 'form' do
      fill_in Customer.human_attribute_name('name'), with: 'Yoda'
      fill_in Customer.human_attribute_name('lastname'), with: 'Master'
      fill_in Customer.human_attribute_name('identification'), with: '060'
      fill_in Customer.human_attribute_name('email'), with: 'yoda@galactic.com'
      fill_in Customer.human_attribute_name('password'), with: 'lightsaber'
      fill_in Customer.human_attribute_name('password_confirmation'),
        with: 'lightsaber'
      select(
        I18n.t('view.customers.kinds.reliable'), from: 'customer_kind'
      )

      assert_difference(
        ['Customer.count', 'Customer.reliables.count']
      ) do
        click_button I18n.t(
          'helpers.submit.create', model: Customer.model_name.human
        )
      end
    end

    assert_page_has_no_errors!
    id = Customer.order('created_at DESC, id DESC').first.id
    assert_equal customer_path(id), current_path
    assert page.has_css?(
      '.alert', text: I18n.t('view.customers.correctly_created')
    )
  end

  test 'should deposit to a customer' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    visit edit_customer_path(customers(:student_without_bonus))

    find(
      :css, "input[id^='deposit_amount_deposit_customer_deposits_attributes_']"
    ).set(12.5)

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
    login

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
      first(:css, '[data-event=removeItem]').click
      sleep 0.5 # Sino, sigue siendo el mismo nº de antes
    end
  end

  test 'should show the bonuses' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    visit edit_customer_path(customers(:student_without_bonus))

    assert_page_has_no_errors!
    assert_equal(
      edit_customer_path(customers(:student_without_bonus)), current_path
    )

    assert page.has_css?('#bonuses_section', visible: false)
    click_link I18n.t('view.customers.show_bonuses')
    assert page.has_css?('#bonuses_section', visible: true)
  end

  test 'should pay a month debt' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    visit customer_path(customers(:student))

    id = customers(:student).id
    assert_page_has_no_errors!
    assert_equal customer_path(id), current_path

    link_month_to_pay = I18n.t('view.customers.to_pay_prints.month_to_pay')
    href = find_link(link_month_to_pay)[:href]
    click_link link_month_to_pay

    sleep 1 # Capybara read the current_url before the url change
    href = href.match(/\?date\=(\S+)/)[1]
    current_page = current_url.match(/\:54163(\/\S+)/)[1]
    assert_page_has_no_errors!
    assert_equal customer_path(id, date: href), current_page

    assert_difference "Customer.find(#{id}).months_to_pay.count", -1 do
      click_link('pay_month_debt')
      sleep 0.5
    end

    assert_page_has_no_errors!
  end

  test 'should pay total debt' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    visit customer_path(customers(:student))

    assert_page_has_no_errors!
    assert_equal customer_path(customers(:student)), current_path

    id = customers(:student).id
    assert_not_equal Customer.find(id).prints.pay_later.count, 0
    click_link('pay_off_debt')
    sleep 0.5
    assert_equal Customer.find(id).prints.pay_later.count, 0
    assert_page_has_no_errors!
  end

  test 'should get customers filtered with debt' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    visit customers_path

    assert_page_has_no_errors!
    assert_equal customers_path, current_path

    within '.btn-group' do
      first(:css, '.dropdown-toggle').click
      within '.dropdown-menu' do
        click_link I18n.t('view.customers.to_pay_prints.with_debt')
      end
    end

    assert_page_has_no_errors!
    current_page = current_url.match(/\:54163(\S+)/)[1]
    assert_equal customers_path(status: 'with_debt'), current_page
  end
end
