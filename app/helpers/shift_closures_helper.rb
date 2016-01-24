module ShiftClosuresHelper
  def printer_has_counter_script?(printer)
    PrintersApi.available_printers.any? do |pattern|
      printer.match(pattern)
    end
  end
end
