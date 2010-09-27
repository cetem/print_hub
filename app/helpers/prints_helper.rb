module PrintsHelper
  def print_destinations_field(form)
    form.select :printer, Cups.show_destinations.map { |d| [d, d] },
      :prompt => true
  end
end