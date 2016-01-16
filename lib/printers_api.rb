module PrintersApi
  class << self
    def get_counter_for(printer_name)
      Rails.env.development? ? rand(99999) : nil
    end
  end
end
