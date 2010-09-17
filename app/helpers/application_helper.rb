module ApplicationHelper
  # Devuelve el HTML con los links para navegar una lista paginada
  #
  # * _objects_:: Objetos con los que se genera la lista paginada
  def pagination_links(objects)
    previous_label = "&laquo; #{t :'label.previous'}".html_safe
    next_label = "#{t :'label.next'} &raquo;".html_safe

    result = will_paginate objects, :previous_label => previous_label,
      :next_label => next_label, :inner_window => 1, :outer_window => 1

    result ||= content_tag(:div, content_tag(:span, previous_label,
        :class => 'disabled prev_page') + content_tag(:em, 1) +
        content_tag(:span, next_label, :class => 'disabled next_page'),
      :class => :pagination)

    result
  end
end