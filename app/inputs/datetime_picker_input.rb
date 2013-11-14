class DatetimePickerInput < SimpleForm::Inputs::Base
  def input
    if object.respond_to?(attribute_name) && object.send(attribute_name)
      value = I18n.l(object.send(attribute_name), format: :minimal)
    end

    @builder.text_field(
      attribute_name,
      input_html_options.reverse_merge(
        value: value,
        autocomplete: 'off',
        data: { 'datetime-picker' => true }
      )
    ).html_safe
  end
end
