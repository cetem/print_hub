module CustomersHelper
  def show_link_to_customer_prints(customer)
    prints_count = customer.prints.count

    if prints_count > 0
      link_to(
        t('view.customers.print_list', count: prints_count),
        customer_prints_path(customer)
      )
    else
      t('view.customers.without_prints')
    end
  end
  
  def show_link_to_customer_bonuses(customer)
    bonuses_count = customer.bonuses.count

    if bonuses_count > 0
      link_to(
        t('view.customers.bonus_list', count: bonuses_count),
        customer_bonuses_path(customer)
      )
    else
      t('view.customers.without_bonuses')
    end
  end
  
  def show_link_to_customer_non_payments(customer)
    pay_later_count = customer.prints.pay_later.count

    if pay_later_count > 0
      link_to(
        t('view.customers.non_payments_list', count: pay_later_count),
        customer_prints_path(customer, status: 'pay_later')
      )
    else
      t('view.customers.without_non_payments')
    end
  end
  
  def show_button_to_destroy(customer)
    if customer.has_no_orders?
      button_to t('label.delete'), customer,
        confirm: t('messages.confirmation'), method: :delete
    end
  end
  
  def show_total_to_pay_amount(amounts)
    one_sided_price = amounts[:one_sided_count] * amounts[:one_sided_price]
    two_sided_price = amounts[:two_sided_count] * amounts[:two_sided_price]
    
    number_to_currency one_sided_price + two_sided_price
  end
  
  def show_button_to_pay_debt(customer)
    button_to(
      t('view.customers.to_pay_prints.pay_off_debt'),
      pay_off_debt_customer_path(customer),
      method: :put, remote: true, id: 'pay_off_debt',
      form: { 'data-type' => 'html' }
    )
  end
end