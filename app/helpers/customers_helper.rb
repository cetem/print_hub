module CustomersHelper
  def show_link_to_customer_prints(customer)
    prints_count = customer.prints.count

    if prints_count > 0
      text = t('view.customers.print_list', count: prints_count)
      current_user.admin ? link_to(text, customer_prints_path(customer)) : text
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

  def show_button_to_pay_debt(customer)
    link_to(
      t('view.customers.to_pay_prints.pay_off_debt'),
      pay_off_debt_customer_path(customer, format: 'html'),
      method: :patch, remote: true, id: 'pay_off_debt',
      class: 'btn btn-primary', data: { event: 'pay-debt' }
    )
  end

  def show_button_to_pay_month_debt(customer, date)
    date_s = l(Date.parse(date), format: :month_and_year).camelize

    link_to(
      t('view.customers.to_pay_prints.pay', date: date_s),
      pay_month_debt_customer_path(customer, date: date, format: 'html'),
      method: :patch, remote: true, id: 'pay_month_debt',
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

  def link_to_activate_customer(customer)
    link_to '&#xe014;'.html_safe, manual_activation_customer_path(customer),
            class: 'iconic', method: :patch, title: t('view.customers.activate'),
            data: { 'show-tooltip' => true }
  end

  def autocomplete_for_customer_group(form)
    classes = ['autocomplete-field', 'span11']
    classes << 'error' if @customer.errors[:group_id].present?

    inputs = (form.label :group_id)
    inputs << (form.input :auto_group_name, label: false, input_html: {
      value: form.object.try(:group), class: classes.join(' '), data: {
        'autocomplete-id-target' => '#customer_group_id',
        'autocomplete-url' => autocomplete_for_name_customers_groups_path(format: :json)
      }
    })
    inputs << (form.input :group_id, as: :hidden, input_html: {
      value: form.object.try(:group_id), class: 'autocomplete-id'
    })
    inputs
  end
end
