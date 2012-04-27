module PrintsHelper
  def print_destinations_field(form)
    selected_printer = form.object.printer || current_user.default_printer
    
    form.input :printer, collection: Cups.show_destinations.map { |d| [d, d] },
      selected: selected_printer, include_blank: true, autofocus: true,
      wrapper_html: { class: 'column_left' }
  end

  def link_to_cancel_print_job(print_job)
    button = button_to(t('view.prints.cancel_job'),
      cancel_job_print_path(print_job), method: :put, remote: true,
      disable_with: t('view.prints.disabled_cancel_job'),
      disabled: !print_job.pending?)

    content_tag :div, button, id: "cancel_print_job_#{print_job.id}",
      class: 'button_form_container'
  end
  
  def link_to_customer_credit_detail(customer)
    link_to t('view.prints.customer_credit_detail.link'),
      credit_detail_customer_path(customer || {id: 0}),
      id: 'link_to_customer_credit_detail',
      class: 'details_link action_link', remote: true,
      title: t('view.prints.customer_credit_detail.title'),
      style: ('display: none;' unless customer)
  end
  
  def link_to_document_details(document)
    link_to '&#xe054;'.html_safe, document || document_path(id: 0),
      class: 'details_link action_link iconic', remote: true,
      title: t('view.prints.document_details'),
      style: ('display: none;' unless document)
  end
  
  def show_document_stock(print_job)
    stock = print_job.document.try(:stock) || 0
    copies = print_job.copies
    printed_copies = stock > copies ? 0 : copies - stock;
    
    content_tag :span, "##{stock}!#{printed_copies}",
      class: 'document_stock',
      title: t('view.prints.document_stock'),
      style: ('display: none;' if stock == 0 || !print_job.full_document?),
      'data-stock' => stock
  end
  
  def show_print_status(print)
    t("view.prints.status.#{print.status_symbol}")
  end
  
  def there_are_documents_for_printing?
    !session[:documents_for_printing].blank?
  end
  
  def display_print_jobs_codes(print)
    codes = print.print_jobs.includes(:document).select(&:document).map do |pj|
      [pj.document.code, pj.document.name]
    end
    
    out = (codes[0..2]).map do |code, name|
      code = truncate(code.to_s, length: 15, omission: '...')
      
      content_tag(
        :span, code, title: name, class: 'label', data: {'show-tooltip' => true}
      )
    end.join(' ')
    
    if codes.size > 3
      title = codes[3..-1].map { |code, name| "[#{code}] #{name}" }.join(', ')
      
      out << ' '
      out << content_tag(
        :span, raw('&hellip;'), title: title, class: 'label',
        data: {'show-tooltip' => true}
      )
    end
    
    raw content_tag(:div, out.present? ? raw(out) : '-', class: 'nowrap')
  end
end