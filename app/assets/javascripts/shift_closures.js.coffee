new Rule
  condition: -> $('#shift_closure_form').length
  load: ->
    @map.askForPrinterCounter ||= (e)->
      e.preventDefault()
      e.stopPropagation()

      element = $(this)
      printerName = element.data('printer')

      $.ajax
        url: element.data('actionUrl')
        method: 'GET'
        dataType: 'json'
        data: { printer_name: printerName }
        success: (data)->
          if data.counter && data.counter > 0
            $("[data-printer-name='#{printerName}']").val(data.counter)

    $(document).on 'click', '[data-action="ask_for_counters"]', @map.askForPrinterCounter

  unload: ->
    $(document).off 'click', '[data-action="ask_for_counters"]', @map.askForPrinterCounter
