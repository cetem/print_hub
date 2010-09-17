# Reescribe el comportamiento por defecto del etiquetado de los campos con
# errores de validación
ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
    # msg = instance.error_message
    error_class = 'field_with_errors'

    if html_tag =~ /<(input|textarea|select|label)[^>]+class=/
        class_attribute = html_tag =~ /class=['"]/
        html_tag.insert(class_attribute + 7, "#{error_class} ")
    elsif html_tag =~ /<(input|textarea|select|label)/
        first_whitespace = html_tag =~ /\s/
        html_tag[first_whitespace] = " class=\"#{error_class}\" "
    end

    html_tag
end