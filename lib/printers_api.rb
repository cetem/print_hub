module PrintersApi
  class << self
    def available_printers
      [
        /RICOH_Aficio_MP_7500/i,
        /RICOH_Aficio_MP_8000/i,
        /Samsung/i
      ]
    end

    def get_counter_for(printer_name)
      Rails.env.development? ? rand(99999) : nil
    end
  end
end
