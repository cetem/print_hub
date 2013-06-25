@Order =
  updateTotalPrice: ->
    totalPrice = 0.0
    credit = parseFloat($('#user').data('credit')) || 0
       
    Order.updateTotalPages()
    
    $('.order_line:not([data-exclude-from-total])').each ->
      totalPrice += parseFloat($(this).data('price')) || 0
    
    if totalPrice > 0 && (credit >= (totalPrice * Order.threshold))
      $('#not_printed').hide()
      $('#printed').show()
    else if totalPrice > 0
      $('#printed').hide()
      $('#not_printed').show()
    
    money = $('#total span.money')
    
    money.html(money.html().replace(/(\d+.)+\d+/, totalPrice.toFixed(3)))
  
  updateOrderLinePrice: (orderLine)->
    Order.updateTotalPages()
    Jobs.updatePricePerCopy('.order_line')

    orderLinesContainer = $('div[data-jobs-container]')
    mediaType = orderLine.find(
      'select[name$="[print_job_type_id]"] :selected'
    ).val()

    copies = parseInt(orderLine.find('input[name$="[copies]"]').val())
    pages = parseInt(orderLine.find('input[name$="[pages]"]').val())
    totalPages = pages * copies
    evenPages = totalPages - (totalPages % 2)
    rest = (totalPages % 2)

    pricePerCopy = orderLine.data('price-per-copy')
    oneSidedType = orderLinesContainer.data('prices-one-sided')[mediaType] || mediaType
    oneSidedSettings = orderLinesContainer.data('prices-list')[oneSidedType]
    mediaPages = orderLinesContainer.data('pages-list')[mediaType]

    oneSidedPages = if rest then mediaPages || rest else 0
    pricePerOneSidedCopy = PriceChooser.choose(
      oneSidedSettings, parseInt(oneSidedPages)
    )
    jobPrice = parseFloat(
      (pricePerCopy * evenPages + pricePerOneSidedCopy) || 0
    ).toFixed(3)

    money = orderLine.find('span.money')
    orderLine.data('price', jobPrice)
    money.html(money.html().replace(/(\d+.)+\d+/, jobPrice))

    Order.updateTotalPrice()

  updateTotalPages: ->
    totalTypePages = $('[data-jobs-container]').data('pages-list')

    # Reset the counts
    $.each totalTypePages, (key, value) ->
      totalTypePages[key] = 0

    $('.order_line:not([data-exclude-from-total])').each (i, ol)->
      copies = parseInt $(ol).find('input[name$="[copies]"]').val()
      pages = parseInt($(ol).find('input[name$="[pages]"]').val()) || 0

      jobType = $(ol).find('select[name$="[print_job_type_id]"] :selected').val()

      totalTypePages[jobType] += (copies * pages) || 0

  updateAllOrderLines: ->
    $('.order_line:not([data-exclude-from-total])').each ->
      Order.updateTotalPages()
      Order.updateOrderLinePrice $(this)


new Rule
  condition: -> $('#ph_orders').length
  load: ->
    # Actualizar precios
    Order.updateAllOrderLines()
    Jobs.listenPrintJobTypeChanges('.order_line')

    # Mostrar detalles del documento
    @map.showDocumentDetails ||= (event, data)->
      Helper.show(
        $(this).parents('.order_line').find('.dynamic_details').hide().html(data)
      )
    
    # Eliminar item de la orden
    @map.removeItem ||= (event, element)->
      if $(element).hasClass('order_line')
        $(element).attr('data-exclude-from-total', '1')
        Order.updateTotalPrice()

    # Al hacer click en botón imprimir -> Imprimir =)
    @map.print ||= (event)->
      window.print()
      
      event.preventDefault()
      event.stopPropagation()
    
    @map.skipFileWarning ||= ->
      State.fileUploaded = false
      $(this).preventDefault()

    $(document).on 'click', '.skip-file-warning', @map.skipFileWarning
    $(document).on 'ajax:success', 'a.details-link', @map.showDocumentDetails
    $(document).on 'item.removed', @map.removeItem
    $(document).on 'change keyup', '.price-modifier, .page-modifier, .order_file',
      Order.updateAllOrderLines
    $(document).on 'click', 'a[data-action="print"]', @map.print
    
  unload: ->
    $(document).off 'click', '.skip-file-warning', @map.skipFileWarning
    $(document).off 'ajax:success', 'a.details-link', @map.showDocumentDetails
    $(document).off 'item.removed', @map.removeItem
    $(document).off 'change keyup', '.price-modifier, .page-modifier, .order_file',
      Order.updateAllOrderLines
    $(document).off 'click', 'a[data-action="print"]', @map.print


new Rule
  condition: -> $('#order_file_file').length
  load: ->
    # Subir un archivo para agregarlo a la orden
    $('input:file').fileupload
      dataType: 'script'
      add: (e, data) ->
        type = /(pdf)$/i
        file = data.files[0]

        if type.test(file.type) || type.test(file.name)
          $('#file-upload-error').hide()
          $('.progress.hide').toggle('slow')
          $('#upload-file .file').toggle('slow')
          $('input:submit').attr('disabled', true)
          data.submit()
        else
          $('#file-upload-error').show('slow')
      
      progressall: (e, data) ->
        progress = parseInt(data.loaded / data.total * 100, 10)
        $('.progress .bar').css('width', progress + '%')

      done: (e, data) ->
        $('.progress.hide').toggle('slow')
        $('#upload-file .file').toggle('slow')
        $('input:submit').attr('disabled', false)
        State.fileUploaded = true
        $('.order_file:last').change()
