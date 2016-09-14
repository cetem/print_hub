module ApplicationHelper
  def textilize(text)
    if text.blank?
      ''
    else
      textilized = RedCloth.new(text, [:hard_breaks])
      textilized.hard_breaks = true if textilized.respond_to?(:'hard_breaks=')
      textilized.to_html.html_safe
    end
  end

  def textilize_without_paragraph(text)
    textiled = textilize(text)

    textiled = textiled[3..-1] if textiled[0..2] == '<p>'
    textiled = textiled[0..-5] if textiled[-4..-1] == '</p>'

    textiled.html_safe
  end

  # Devuelve una etiqueta con el mismo nombre que el del objeto para que sea
  # reemplazado con un ID único por la rutina que reemplaza todo en el navegador
  def dynamic_object_id(prefix, form_builder)
    "#{prefix}_#{form_builder.object_name.to_s.gsub(/[_\]\[]+/, '_')}".gsub(
      /(\d+)/, form_builder.object_id.to_s
    )
  end

  def dynamic_object_name(form_builder)
    form_builder.object_name.gsub(/(\d+)/, form_builder.object_id.to_s)
  end

  # Devuelve los mensajes de error con etiquetas HTML
  def show_error_messages(model)
    render 'shared/error_messages', model: model unless model.errors.empty?
  end

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

  # Devuelve el HTML necesario para insertar un nuevo ítem en un nested form
  #
  # * _form_builder_::  Formulario "Padre" de la relación anidada
  # * _method_::        Método para invocar la relación anidada (por ejemplo, si
  #                     se tiene una relación Post > has_many :comments, el método
  #                     en ese caso es :comments)
  # * _user_options_::  Optiones del usuario para "personalizar" la generación de
  #                     HTML.
  #    object objeto asociado
  #    partial partial utilizado para generar el HTML
  #    form_builder_local => nombre de la variable que contiene el objeto form
  #    locals Hash con las variables locales que necesita el partial
  #    child_index nombre que se pondrá en el lugar donde se debe reemplazar
  #                    por el índice adecuado (por defecto NEW_RECORD)
  #    is_dynamic se establece a true si se está generando para luego ser
  #                   insertado múltiples veces.
  def generate_html(form_builder, method, user_options = {})
    options = {
      object: form_builder.object.class.reflect_on_association(method).klass.new,
      partial: method.to_s.singularize,
      form_builder_local: :f,
      locals: {},
      child_index: 'NEW_RECORD',
      is_dynamic: true
    }.merge(user_options)

    form_builder.fields_for(method, options[:object], child_index: options[:child_index]) do |f|
      render(options[:partial], {
        options[:form_builder_local] => f, is_dynamic: options[:is_dynamic]
      }.merge(options[:locals])
            )
    end
  end

  # Genera el mismo HTML que #generate_html con la diferencia que lo escapa para
  # que pueda ser utilizado en javascript.
  def generate_template(form_builder, method, options = {})
    escape_javascript generate_html(form_builder, method, options)
  end

  # Devuelve HTML con un link para eliminar un componente de un formulario
  #
  # * _fields_:: El objeto form para el que se va a generar el link
  def link_to_remove_nested_item(fields = nil, class_for_remove = nil)
    new_record = fields.nil? || fields.object.new_record?
    out = ''
    out << fields.hidden_field(:_destroy, class: :destroy,
                                          value: fields.object.marked_for_destruction? ? 1 : 0) unless new_record
    out << link_to(
      '&#x2718;'.html_safe, '#', title: t('label.delete'), class: 'iconic',
                                 'data-target' => ".#{class_for_remove || fields.object.class.name.underscore}",
                                 'data-event' => (new_record ? 'removeItem' : 'hideItem')
    )

    raw out
  end

  # Devuelve el HTML con los links para navegar una lista paginada
  #
  # * _objects_:: Objetos con los que se genera la lista paginada
  def pagination_links(objects, params = nil)
    result = will_paginate objects,
                           inner_window: 1, outer_window: 1, params: params,
                           renderer: BootstrapPaginationHelper::LinkRenderer,
                           class: 'pagination pagination-right'
    page_entries = content_tag(
      :blockquote,
      content_tag(
        :small,
        page_entries_info(objects),
        class: 'page-entries hidden-desktop pull-right'
      )
    )

    unless result
      previous_tag = content_tag(
        :li,
        content_tag(:a, t('will_paginate.previous_label').html_safe),
        class: 'previous_page disabled'
      )
      next_tag = content_tag(
        :li,
        content_tag(:a, t('will_paginate.next_label').html_safe),
        class: 'next disabled'
      )

      result = content_tag(
        :div,
        content_tag(:ul, previous_tag + next_tag),
        class: 'pagination pagination-right'
      )
    end

    result + page_entries
  end

  def sortable(column, title = nil)
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'
    query = request.query_parameters.merge(sort: column, direction: direction)

    link_to(
      title || column.titleize, "#{request.path}?#{query.to_query}",
      { class: css_class, title: request.path.class }
    )
  end

  def image_sprite(image, options = {})
    sprites = {
      copyleft: { w: 70, h: 40, x: 0, y: 10 },
      solidarity: { w: 70, h: 40, x: 0, y: -50 },
      transformation: { w: 70, h: 40, x: 0, y: -100 }
    }
    style = <<-CSS
      background: url(#{image_path('welcome/sprites.gif')})
        no-repeat -#{sprites[image][:x]}px #{sprites[image][:y]}px;
      width: #{sprites[image][:w]}px;
      padding-top: #{sprites[image][:h]}px;
      #{options[:style]}
    CSS

    content_tag('span', options[:title],
                class: "sprite #{options[:class]}",
                style: style,
                title: "#{options[:title]}"
               )
  end

  def explorer?
    request.env['HTTP_USER_AGENT'] =~ /msie/i
  end

  def boolean_collection
    [
      [t('label.yes'), true],
      [t('label.no'), false]
    ]
  end

  def translate_boolean(value)
    value ? t('label.yes') : t('label.no')
  end
end
