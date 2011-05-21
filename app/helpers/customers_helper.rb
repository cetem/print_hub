module CustomersHelper
  def show_link_to_customer_prints(customer)
    prints_count = customer.prints.count

    if prints_count > 0
      link_to(
        t(:print_list, :count => prints_count, :scope => [:view, :customers]),
        customer_prints_path(customer)
      )
    else
      t(:without_prints, :scope => [:view, :customers])
    end
  end
  
  def show_link_to_customer_bonuses(customer)
    bonuses_count = customer.bonuses.count

    if bonuses_count > 0
      link_to(
        t(:bonus_list, :count => bonuses_count, :scope => [:view, :customers]),
        customer_bonuses_path(customer)
      )
    else
      t(:without_bonuses, :scope => [:view, :customers])
    end
  end
end