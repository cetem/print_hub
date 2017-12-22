module ShiftClosuresHelper
  def printer_has_counter_script?(printer)
    ::PrintersApi.has_counter_script?(printer)
  end

  def number_to_delimited(number)
    number_to_currency(number, unit: '', precision: 0, delimiter: '.')
  end

  def show_who_changed_version(version)
    User.find(version.whodunnit)
  end
end
