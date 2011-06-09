module ApplicationHelper
  def textilize(text)
    if text.blank?
      ''
    else
      textilized = RedCloth.new(text, [ :hard_breaks ])
      textilized.hard_breaks = true if textilized.respond_to?(:'hard_breaks=')
      textilized.to_html.html_safe
    end
  end

  def textilize_without_paragraph(text)
    textiled = textilize(text)

    if textiled[0..2] == '<p>' then textiled = textiled[3..-1] end
    if textiled[-4..-1] == '</p>' then textiled = textiled[0..-5] end

    textiled.html_safe
  end

  def default_stylesheets
    sheets = ['common', 'jquery/ui-custom', 'jquery/fancybox']
    sheets << {:cache => 'main'}

    stylesheet_link_tag *sheets
  end

  def default_javascripts
    libs = [:defaults, 'utils', 'jquery.fancybox', 'jquery-ui-timepicker-addon', 'datepicker/jquery.ui.datepicker-es']
    libs << {:cache => 'main'}

    javascript_include_tag *libs
  end

  # Devuelve una etiqueta con el mismo nombre que el del objeto para que sea
  # reemplazado con un ID único por la rutina que reemplaza todo en el navegador
  def dynamic_object_id(prefix, form_builder)
    "#{prefix}_#{form_builder.object_name.to_s.gsub(/[_\]\[]+/, '_')}"
  end

  # Devuelve los mensajes de error con etiquetas HTML
  def show_error_messages(model)
    unless model.errors.empty?
      render :partial => 'shared/error_messages', :locals => { :model => model }
    end
  end

  # Devuelve el HTML necesario para insertar un nuevo ítem en un nested form
  #
  # * _form_builder_::  Formulario "Padre" de la relación anidada
  # * _method_::        Método para invocar la relación anidada (por ejemplo, si
  #                     se tiene una relación Post > has_many :comments, el método
  #                     en ese caso es :comments)
  # * _user_options_::  Optiones del usuario para "personalizar" la generación de
  #                     HTML.
  #    :object => objeto asociado
  #    :partial => partial utilizado para generar el HTML
  #    form_builder_local => nombre de la variable que contiene el objeto form
  #    :locals => Hash con las variables locales que necesita el partial
  #    :child_index => nombre que se pondrá en el lugar donde se debe reemplazar
  #                    por el índice adecuado (por defecto NEW_RECORD)
  #    :is_dynamic => se establece a true si se está generando para luego ser
  #                   insertado múltiples veces.
  def generate_html(form_builder, method, user_options = {})
    options = {
      :object => form_builder.object.class.reflect_on_association(method).klass.new,
      :partial => method.to_s.singularize,
      :form_builder_local => :f,
      :locals => {},
      :child_index => 'NEW_RECORD',
      :is_dynamic => true
    }.merge(user_options)

    form_builder.fields_for(method, options[:object],
      :child_index => options[:child_index]) do |f|
      render(:partial => options[:partial], :locals => {
          options[:form_builder_local] => f,
          :is_dynamic => options[:is_dynamic]
        }.merge(options[:locals]))
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
    out = String.new
    out << fields.hidden_field(:_destroy, :class => :destroy,
      :value => fields.object.marked_for_destruction? ? 1 : 0) unless new_record
    out << link_to('X', '#', :title => t(:'label.delete'),
      :'data-target' => ".#{class_for_remove || fields.object.class.name.underscore}",
      :'data-event' => (new_record ? 'removeItem' : 'hideItem'))

    raw out
  end

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