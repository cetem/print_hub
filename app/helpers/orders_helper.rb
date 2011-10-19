module OrdersHelper
  def link_to_show_order(text, order)
    link_to(text,
      current_customer ? order : order_path(order, type: order_type)
    )
  end
  
  def nav_links_in_show_order(order)
    out = []
    
    if current_customer
      out << link_to_if(order.pending?, t('label.edit'), edit_order_path(order))
      out << link_to_if(order.pending?, t('view.orders.cancel'), order,
        confirm: t('messages.confirmation'), method: :delete
      )
      out <<  link_to(t('label.back'), catalog_path)
    else
      out << link_to_if(order.pending?, t('view.orders.new_print'),
        new_print_path(order_id: order.id)
      )
      out << link_to_if(order.pending?, t('view.orders.cancel'),
        order_path(order, type: order_type),
        confirm: t('messages.confirmation'), method: :delete
      )
      out << link_to(t('label.list'), orders_path(type: order_type))
    end
    
    raw out.join(' | ')
  end
  
  def show_orders_table_caption
    unless current_customer
      content_tag(:caption,
        raw(textilize_without_paragraph(t("view.orders.type.#{order_type}")))
      )
    end
  end
  
  def orders_text
    count = Order.pending_for_print_count
    count_tag = content_tag(
      :span, count, id: 'orders_count', class: ('look_me' if count > 0)
    )
    
    raw(t('menu.orders') + count_tag)
  end
end