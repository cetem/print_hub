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
end