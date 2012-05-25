class DatetimePickerInput < SimpleForm::Inputs::Base
  def input
    @builder.text_field(
      attribute_name,
      input_html_options.reverse_merge(
        value: (I18n.l(object.send(attribute_name), format: :minimal) if object.send(attribute_name)),
        autocomplete: 'off',
        data: { 'datetime-picker' => true }
      )
    ).html_safe
  end
end