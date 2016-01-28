module ShiftClosuresHelper
  def printer_has_counter_script?(printer)
    PrintersApi.has_counter_script?(printer)
  end
end
