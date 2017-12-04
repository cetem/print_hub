module PrintsHelper
  def print_destinations_field(form)
    selected_printer = form.object.printer || current_user.default_printer
    printers_collection = []

    CustomCups.show_destinations.sort_by {|k,v| v}.each do |k, v|
      unless k.match(PRIVATE_PRINTERS_REGEXP) && !current_user.admin?
        printers_collection << [v, k]
      end
    end

    form.input :printer, collection: printers_collection,
                         selected: selected_printer, include_blank: true, autofocus: true,
                         input_html: { class: 'span11' }
  end

  def link_to_cancel_print_job(print_job)
    if print_job.pending?
      button = link_to(
        t('view.prints.cancel_job'), cancel_job_print_path(print_job),
        method: :patch, remote: true, class: 'btn btn-mini',
        data: { 'disable-with' => t('view.prints.disabled_cancel_job') }
      )
    else
      button = content_tag(
        :span, t('view.prints.cancel_job'), class: 'btn btn-mini disabled'
      )
    end

    content_tag :div, button, id: "cancel_print_job_#{print_job.id}"
  end

  def link_to_customer_credit_detail(customer)
    link_to t('view.prints.customer_credit_detail.link'),
            credit_detail_customer_path(customer || { id: 0 }),
            id: 'link_to_customer_credit_detail',
            title: t('view.prints.customer_credit_detail.title'),
            class: 'btn btn-mini',
            style: ('display: none;' unless customer),
            data: { toggle: 'modal', target: '#customer_credit_details' }
  end

  def link_to_document_details(document)
    link_to '&#xe054;'.html_safe, document || document_path(id: 0),
            class: 'details-link iconic', remote: true,
            title: t('view.prints.document_details'),
            style: ('display: none;' unless document)
  end

  def show_document_stock(print_job)
    stock = print_job.document.try(:stock) || 0
    copies = print_job.copies
    printed_copies = stock > copies ? 0 : copies - stock

    content_tag :span, "##{stock}!#{printed_copies}",
                class: 'document_stock label label-important',
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
        :span, code, title: name, class: 'label', data: { 'show-tooltip' => true }
      )
    end.join(' ')

    if codes.size > 3
      title = codes[3..-1].map { |code, name| "[#{code}] #{name}" }.join(', ')

      out << ' '
      out << content_tag(
        :span, raw('&hellip;'), title: title, class: 'label',
                                data: { 'show-tooltip' => true }
      )
    end

    raw content_tag(:div, out.present? ? raw(out) : '-', class: 'nowrap')
  end

  def print_customer_label(customer)
    label = Print.human_attribute_name('customer')

    label << '<span class="pull-right">'

    if customer
      label << ' '
      label << link_to(
        t('view.prints.unlink_customer'), '#',
        data: { action: 'clear-customer' },
        class: 'btn btn-mini remove'
      )
    end

    label << ' '
    label << link_to_customer_credit_detail(customer)
    label << '</span>'

    raw(label)
  end

  def show_print_articles_tab_title
    articles_title = t('view.prints.article_lines')

    if @print.article_lines.size > 0
      articles_title << ' '
      articles_title << content_tag(
        :span, @print.article_lines.size, class: 'badge badge-info'
      )
    end

    link_to(
      articles_title.html_safe, '#articles_container', data: { toggle: 'tab' }
    )
  end

  def show_related_by_customer_links
    output = []

    %w(prev next).each do |operator|
      output << link_to(
        textilize_without_paragraph(t("view.prints.customer_links.#{operator}")),
        related_by_customer_print_path(type: operator)
      )
    end

    raw output.join(' | ')
  end

  def show_document_name_in_print_job(print_job)
    if print_job.document_id
      print_job.document
    elsif print_job.file_line_id
      file_line = print_job.file_line

      link_to(file_line.file_name, file_line.file.url)
    end
  end

  def build_print_file_line_form
    form = nil

    simple_fields_for(@print) do |f|
      f.simple_fields_for(:print_jobs) do |job|
        form = job
      end
    end

    form
  end
end
