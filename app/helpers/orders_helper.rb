module OrdersHelper
  def nav_links_in_show_order(order)
    out = []

    if current_customer
      out << link_to_if(order.pending?, t('label.edit'), edit_order_path(order))
      out << link_to_if(order.pending?, t('view.orders.cancel'), order,
                        method: :delete, data: { confirm: t('messages.confirmation') }
                       )
      out << link_to(t('label.back'), catalog_path)
    else
      out << link_to_if(order.pending?, t('view.orders.new_print'),
                        new_print_path(order_id: order.id)
                       )
      out << link_to_if(order.pending?, t('view.orders.cancel'),
                        order_path(order, type: 'all'),
                        method: :delete, data: { confirm: t('messages.confirmation') }
                       )
      out << link_to(t('label.list'), orders_path(type: 'print'))
    end

    raw out.join(' | ')
  end

  def show_orders_table_caption
    unless current_customer
      content_tag(
        :caption,
        content_tag(
          :p, t("view.orders.type.#{order_type || 'all'}.html"), class: 'lead'
        )
      )
    end
  end

  def orders_text
    count = Order.pending_for_print_count
    classes = ['badge']
    classes << 'badge-important' if count > 0
    count_tag = content_tag(
      :span, count, id: 'orders_count', class: classes.join(' ')
    )

    raw("#{t('menu.orders')} #{count_tag}")
  end

  def build_order_file_line_form
    form = nil

    simple_fields_for(@order) do |f|
      f.simple_fields_for(:file_lines) do |of|
        form = of
      end
    end

    form
  end

  def default_price_per_copy_for_pages(pages)
    if pages.present? && pages.to_i > 0
      ::PriceChooser.choose(
        type: PrintJobType.default.try(:id),
        copies: pages.to_i
      )
    end
  end
end
