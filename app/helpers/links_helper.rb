module LinksHelper
  def link_to_show(*args)
    options = args.extract_options!

    options['class'] ||= 'iconic'
    options['title'] ||= t('label.show')
    options['data-show-tooltip'] = true

    link_to '&#xe074;'.html_safe, *args, options
  end

  def link_to_edit(*args)
    options = args.extract_options!

    options['class'] ||= 'iconic'
    options['title'] ||= t('label.edit')
    options['data-show-tooltip'] = true

    link_to '&#x270e;'.html_safe, *args, options
  end

  def link_to_destroy(*args)
    options = args.extract_options!

    options['class'] ||= 'iconic'
    options['title'] ||= t('label.delete')
    options['method'] ||= :delete
    options['data-confirm'] ||= t('messages.confirmation')
    options['data-show-tooltip'] = true

    link_to '&#xe05a;'.html_safe, *args, options
  end

  def link_to_remote_modal(path, modal_selector, *args)
    options = args.extract_options!

    options['class'] ||= 'iconic'
    options['title'] ||= t('label.show')
    options['data-show-tooltip'] = true
    options['data-target'] = modal_selector
    options['data-toggle'] = 'modal'

    link_to '&#xe074;'.html_safe, path, *args, options
  end

  # Devuelve HTML con un link para eliminar un componente de un formulario
  #
  # * _fields_:: El objeto form para el que se va a generar el link
  def link_to_remove_nested_item(fields = nil, class_for_remove = nil)
    new_record = fields.nil? || fields.object.new_record?
    out = ''
    unless new_record
      out << fields.hidden_field(
        :_destroy, class: :destroy,
        value: fields.object.marked_for_destruction? ? 1 : 0
      )
    end

    out << link_to(
      '&#x2718;'.html_safe, '#', title: t('label.delete'), class: 'iconic',
                                 'data-target' => ".#{class_for_remove || fields.object.class.name.underscore}",
                                 'data-event' => (new_record ? 'removeItem' : 'hideItem')
    )

    raw out
  end

  def link_to_copy(*args)
    options = args.extract_options!

    options['class'] ||= 'iconic'
    options['title'] ||= t('label.copy')
    options['data-show-tooltip'] = true

    link_to '&#xe000;'.html_safe, *args, options
  end
end
