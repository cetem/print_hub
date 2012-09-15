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
      button_to t('label.delete'), customer, method: :delete,
        data: { confirm: t('messages.confirmation') }
    end
  end
  
  def show_total_to_pay_amount(amounts)
    one_sided_price = amounts[:one_sided_count] * amounts[:one_sided_price]
    two_sided_price = amounts[:two_sided_count] * amounts[:two_sided_price]
    
    number_to_currency one_sided_price + two_sided_price
  end
  
  def show_button_to_pay_debt(customer)
    link_to(
      t('view.customers.to_pay_prints.pay_off_debt'),
      pay_off_debt_customer_path(customer, format: 'html'),
      method: :put, remote: true, id: 'pay_off_debt',
      class: 'btn btn-primary', data: { event: 'pay-debt' }
    )
  end

  def show_button_to_pay_month_debt(customer, date)
    date_s = l(Date.parse(date), format: :month_and_year).camelize
    
    link_to(
      t('view.customers.to_pay_prints.pay', date: date_s),
      pay_month_debt_customer_path(customer, date: date, format: 'html'),
      method: :put, remote: true, id: 'pay_month_debt',
      class: 'btn btn-primary', data: { event: 'pay-debt' }
    )
  end

  def show_customer_first_month_to_pay(customer)
    m_y = customer.months_to_pay.first
    "#{m_y.last}-#{m_y.first}-1"
  end

  def show_customer_select_with_debt_months(customer)
    customer.months_to_pay.inject([]) do |date, m_y|
      date + [[l(Date.new(m_y.last, m_y.first, 1), format: :month_and_year), 
        "#{m_y.last}-#{m_y.first}-1"]]
    end
  end

  def show_customer_the_only_month_of_debt(customer)
    month = customer.months_to_pay.first
    l(Date.new(month.last, month.first, 1), format: :month_and_year)
  end

  def select_for_customer_kinds(form)
    kinds = Customer::KINDS.map { |k, v| [t("view.customers.kinds.#{k}"), v] }

    form.input :kind, collection: kinds, prompt: false,
      input_html: { class: 'span11' }
  end
end
