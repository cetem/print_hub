module CustomCups
  extend self
  @@_printers_file = {}

  def show_destinations
    printers_file.split("\n").inject({}) do |memo, item|
      if item.start_with?('#')
        memo
      else
        _item, id, name = *item.match(/^(.+)\|(.+):rm/)
        memo.merge!({ id => name })
      end
    end
  end

  def printers_file
    if @@_printers_file[:time].to_i > 10.minutes.ago.to_i
      # cache
      return @@_printers_file[:file]
    end

    @@_printers_file[:time] = Time.zone.now.to_i
    @@_printers_file[:file] = `cat /etc/printcap`
  end
end
