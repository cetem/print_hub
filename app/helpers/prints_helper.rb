module PrintsHelper
  def print_destinations_field(form)
    selected = form.object.printer || current_user.default_printer
    
    form.select :printer, Cups.show_destinations.map { |d| [d, d] },
      { :include_blank => true, :selected => selected }, { :autofocus => true }
  end

  def link_to_cancel_print_job(print_job)
    button = button_to(t(:cancel_job, :scope => [:view, :prints]),
      cancel_job_print_path(print_job), :method => :put, :remote => true,
      :disable_with => t(:disabled_cancel_job, :scope => [:view, :prints]),
      :disabled => !print_job.pending?)

    content_tag :div, button, :id => "cancel_print_job_#{print_job.id}",
      :class => :button_form_container
  end
  
  def link_to_customer_credit_detail(customer)
    link_to t(:'view.prints.customer_credit_detail.link'),
      credit_detail_customer_path(customer || {:id => 0}),
      :id => :link_to_customer_credit_detail,
      :class => 'details_link action_link', :remote => true,
      :title => t(:'view.prints.customer_credit_detail.title'),
      :style => ('display: none;' unless customer)
  end
end