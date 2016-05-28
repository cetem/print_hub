require 'test_helper'

class OrdersTest < ActionDispatch::IntegrationTest

  test 'should print an order' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    within '.nav-collapse' do
      click_link I18n.t('menu.orders')
    end

    assert_page_has_no_errors!

    within '.form-actions' do
      click_link I18n.t('view.orders.show_all').gsub('*', '')
    end

    assert_page_has_no_errors!
    assert_equal orders_path, current_path

    show_href = nil
    link_with_show_title = "a[data-original-title='#{I18n.t('label.show')}']"
    assert page.has_css?(link_with_show_title)

    within 'table tbody' do
      show_href = first(:css, link_with_show_title)[:href]
      first(:css, link_with_show_title).click
    end

    id = show_href.match(/\/(\d+)/)[1]
    order = Order.find(id.to_i)
    assert order.pending?

    assert_page_has_no_errors!
    assert_equal order_path(id), current_path

    within '.form-actions' do
      click_link I18n.t('view.orders.new_print')
    end

    assert_page_has_no_errors!
    assert_equal new_print_path, current_path

    within 'form' do
      select(
        Cups.show_destinations.detect { |p| p =~ /pdf/i }, from: 'print_printer'
      )
      assert_difference 'Print.count' do
        click_button I18n.t('view.prints.print_title')
      end
    end

    assert_page_has_no_errors!
    assert page.has_css?(
      '.alert', text: I18n.t('view.prints.correctly_created')
    )

    last_print = Print.order('id DESC').first
    assert_equal print_path(last_print), current_path

    within '.form-actions' do
      click_link I18n.t('label.list')
    end

    assert_page_has_no_errors!
    assert_equal prints_path, current_path
  end

  test 'should print an order of reliable customer' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    within '.nav-collapse' do
      click_link I18n.t('menu.orders')
    end

    assert_page_has_no_errors!

    within '.form-actions' do
      click_link I18n.t('view.orders.show_all').gsub('*', '')
    end

    assert_page_has_no_errors!
    assert_equal orders_path, current_path

    customer = customers(:student)
    debt = customer.to_pay_amounts[:total_price]

    order = orders(:from_yesterday)
    order.customer_id = customer.id
    order.save

    link = "a[href='/orders/#{order.id}?type=all']"

    within 'table tbody' do
      first(:css, link).click
    end

    assert_page_has_no_errors!
    assert_equal order_path(order.id), current_path

    within '.form-actions' do
      click_link I18n.t('view.orders.new_print')
    end

    assert_page_has_no_errors!
    assert_equal new_print_path, current_path

    within 'form' do
      select(
        Cups.show_destinations.detect { |p| p =~ /pdf/i }, from: 'print_printer'
      )

      assert find('#print_pay_later').checked?
      assert find('#payment_C_amount').value.to_f == 0.0
      assert find('#payment_C_paid').value.to_f == 0.0

      assert_difference 'Print.count' do
        click_button I18n.t('view.prints.print_title')
      end
    end

    new_debt = customer.reload.to_pay_amounts[:total_price]

    assert_not_equal debt, new_debt
    assert_equal debt + order.price, new_debt

    assert_page_has_no_errors!
    assert page.has_css?(
      '.alert', text: I18n.t('view.prints.correctly_created')
    )
  end

  test 'should cancel an order' do
    login

    assert_page_has_no_errors!
    assert_equal prints_path, current_path

    within '.nav-collapse' do
      click_link I18n.t('menu.orders')
    end

    assert_page_has_no_errors!

    within '.form-actions' do
      click_link I18n.t('view.orders.show_all').gsub('*', '')
    end

    assert_page_has_no_errors!
    assert_equal orders_path, current_path

    show_href = nil
    link_with_show_title = "a[data-original-title='#{I18n.t('label.show')}']"
    assert page.has_css?(link_with_show_title)

    within 'table tbody' do
      show_href = first(:css, link_with_show_title)[:href]
      first(:css, link_with_show_title).click
    end

    id = show_href.match(/\/(\d+)/)[1]
    order = Order.find(id.to_i)
    assert order.pending?

    assert_page_has_no_errors!
    assert_equal order_path(id), current_path

    within '.form-actions' do
      assert_difference 'Order.cancelled.count' do
        click_link I18n.t('view.orders.cancel')
        sleep(1)
        page.driver.browser.switch_to.alert.accept
        sleep(1)
      end
    end

    assert_page_has_no_errors!
    assert_equal order_path(id), current_path
    assert page.has_css?(
      '.alert', text: I18n.t('view.orders.correctly_cancelled')
    )
  end
end
