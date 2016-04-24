module PrintersApi
  class << self
    def available_printers
      [
        /RICOH_Aficio_MP_7500/i,
        /RICOH_Aficio_MP_8000/i,
        /RICOH_Aficio_SP_8300/i,
        /Plotter/i,
        /Brother/i,
        /Samsung/i
      ]
    end

    def has_counter_script?(printer)
      available_printers.any? { |pattern| printer.match(pattern) }
    end

    def get_counter_for(printer_name)
      return unless has_counter_script?(printer_name)

      # Force the timeout here because of open(read_timeout) always
      # put double (real) timeout.
      # open(url, read_timeout: 10) => always waits 20seg,
      # so we don't trust in that
      timeout(10) do
        ip = get_printer_ip(printer_name)
        return if ip.blank?
        case
          when printer_name.match(/ricoh/i)
            ricoh_web_monitor_for_ip(ip)
          when printer_name.match(/brother/i)
            brother_web_monitor_for_ip(ip)
          when printer_name.match(/plotter/i)
            plotter_web_monitor_for_ip(ip)
          when printer_name.match(/samsung/i)
            42
        end
      end
    rescue Timeout::Error
      nil
    rescue => e
      Bugsnag.notify(e)
      nil
    end

    def get_printer_ip(printer)
      Cups.options_for(printer)['device-uri'].match(/(\d{,3}\.\d{,3}\.\d{,3}\.\d{,3})/)[1]
    rescue => e
      Bugsnag.notify(e)
      nil
    end

    def plotter_web_monitor_for_ip(ip)
      page = open("http://#{ip}/#hId-devInfoPage")
      parsed = Nokogiri::HTML(page)
      parsed.css(
        'tr.gui-list-tbl-odd-row,td:contains("Recuento Total de páginas"):first'
      ).css('td').last.text
    end

    def brother_web_monitor_for_ip(ip)
      page = open("http://#{ip}/main/main.html?weblang=2")
      parsed = Nokogiri::HTML(page)
      parsed.css(
        'td.elemwhite:contains("Page Counter"):first'
      ).children.text.match(/(\d+)/)[1].to_i
    end

    def ricoh_web_monitor_for_ip(ip)
      page = open(
        "http://#{ip}/web/guest/es/websys/status/getUnificationCounter.cgi"
      )
      parsed = Nokogiri::HTML(page)
      parsed.css('tr.staticProp:contains("Total"):first').children[3].text.to_i
    end
  end
end
