require 'test_helper'

class OrdersTest < ActionDispatch::IntegrationTest
  fixtures :all

  setup do
    Capybara.current_driver = Capybara.javascript_driver # :selenium by default
    Capybara.server_port = '54163'
    Capybara.app_host = "http://localhost:54163"
    page.driver.options[:resynchronize] = true
  end

  
  test 'should print an order' do
    adm_login
    assert_equal prints_path, current_path
    assert_page_has_no_errors!

    within '#main_menu' do
      click_link I18n.t('menu.orders')
    end

    assert_page_has_no_errors!

    within 'nav.links' do
      click_link I18n.t('view.orders.show_all').gsub('*', '')
    end

    assert_page_has_no_errors!
    assert_equal orders_path, current_path

    show_href = nil

    within 'table.list' do
      assert page.has_css?('.even') 
      within ('.even') do
        show_href = find_link(I18n.t('label.show'))[:href]
        click_link I18n.t('label.show')
      end
    end

    id = show_href.match(/\/(\d+)/)[1]
    order = Order.find(id.to_i)
    assert order.pending?
    
    assert_equal order_path(id), current_path
    assert_page_has_no_errors!

    within 'nav.links' do
      click_link I18n.t('view.orders.new_print')
    end

    assert_page_has_no_errors!
    assert_equal new_print_path, current_path


    within 'form.new_print' do
      select(
        Cups.show_destinations.detect { |p| p =~ /pdf/i }, from: 'print_printer'
      )
      assert_difference 'Print.count' do
        click_button I18n.t('view.prints.print_title')
      end
    end

    assert_page_has_no_errors!
    assert page.has_css?('#notice', text: I18n.t('view.prints.correctly_created'))

    last_print = Print.order('id DESC').first
    assert_equal print_path(last_print), current_path

    within 'nav.links' do
      click_link I18n.t('label.list')
    end

    assert_page_has_no_errors!
    assert_equal prints_path, current_path
  end
  
  test 'should cancel an order' do
    adm_login
    assert_equal prints_path, current_path
    assert_page_has_no_errors!

    within '#main_menu' do
      click_link I18n.t('menu.orders')
    end

    assert_page_has_no_errors!

    within 'nav.links' do
      click_link I18n.t('view.orders.show_all').gsub('*', '')
    end

    assert_page_has_no_errors!
    assert_equal orders_path, current_path

    show_href = nil
    
    within 'table.list' do
      within ('.even') do
        show_href = find_link(I18n.t('label.show'))[:href]
        click_link I18n.t('label.show')
      end
    end

    id = show_href.match(/\/(\d+)/)[1]
    order = Order.find(id.to_i)
    assert order.pending?
    
    assert_equal order_path(id), current_path
    assert_page_has_no_errors!
    
    within 'nav.links' do
      assert_difference 'Order.cancelled.count' do
        click_link I18n.t('view.orders.cancel')
        page.driver.browser.switch_to.alert.accept
        sleep(0.5)
      end 
    end

    assert_page_has_no_errors!
    assert_equal order_path(id), current_path
    assert page.has_css?(
      '#notice', text: I18n.t('view.orders.correctly_cancelled')
    )
  end
end
