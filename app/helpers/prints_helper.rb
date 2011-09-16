module PrintsHelper
  def print_destinations_field(form)
    selected = form.object.printer || current_user.default_printer
    printers = Cups.show_destinations.map { |d| [d, d] }
    
    form.select(
      :printer, printers,
      {include_blank: true, selected: selected},
      {autofocus: true}
    )
  end

  def link_to_cancel_print_job(print_job)
    button = button_to(t('view.prints.cancel_job'),
      cancel_job_print_path(print_job), :method => :put, :remote => true,
      :disable_with => t('view.prints.disabled_cancel_job'),
      :disabled => !print_job.pending?)

    content_tag :div, button, :id => "cancel_print_job_#{print_job.id}",
      :class => 'button_form_container'
  end
  
  def link_to_customer_credit_detail(customer)
    link_to t('view.prints.customer_credit_detail.link'),
      credit_detail_customer_path(customer || {:id => 0}),
      :id => 'link_to_customer_credit_detail',
      :class => 'details_link action_link', :remote => true,
      :title => t('view.prints.customer_credit_detail.title'),
      :style => ('display: none;' unless customer)
  end
  
  def link_to_document_details(document)
    link_to '...', document || document_path(:id => 0),
      :class => 'details_link action_link', :remote => true,
      :title => t('view.prints.document_details'),
      :style => ('display: none;' unless document)
  end
  
  def show_document_stock(document, copies)
    stock = document.try(:stock) || 0
    printed_copies = stock > copies ? 0 : copies - stock;
    
    content_tag :span, "##{stock}!#{printed_copies}",
      :class => 'document_stock',
      :title => t('view.prints.document_stock'),
      :style => ('display: none;' if stock == 0),
      'data-stock' => stock
  end
  
  def there_are_documents_for_printing?
    !session[:documents_for_printing].blank?
  end
end