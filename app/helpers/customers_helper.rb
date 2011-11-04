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
end