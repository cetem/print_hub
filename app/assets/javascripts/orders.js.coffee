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
    evenPages = pages - (pages % 2)
    rest = (pages % 2)

    pricePerCopy = orderLine.data('price-per-copy')
    oneSidedType = orderLinesContainer.data('prices-one-sided')[mediaType] || mediaType
    oneSidedSettings = orderLinesContainer.data('prices-list')[oneSidedType]
    mediaPages = orderLinesContainer.data('pages-list')[mediaType]

    oneSidedPages = if rest then mediaPages || rest else 0
    pricePerOneSidedCopy = PriceChooser.choose(
      oneSidedSettings, parseInt(oneSidedPages)
    )
    jobPrice = parseFloat(
      copies * (pricePerCopy * evenPages + pricePerOneSidedCopy) || 0
    ).toFixed(3)

    money = orderLine.find('span.money')
    orderLine.data('price', jobPrice)
    money.html(money.html().replace(/(\d+.)+\d+/, jobPrice))

    Order.updateTotalPrice()

  updateTotalPages: ->
    jobsContainer = $('[data-jobs-container]')
    totalTypePages = jobsContainer.data('pages-list')

    # Reset the counts
    $.each totalTypePages, (key, value) ->
      totalTypePages[key] = 0

    $('.order_line:not([data-exclude-from-total])').each (i, ol)->
      copies = parseInt $(ol).find('input[name$="[copies]"]').val()
      pages = parseInt($(ol).find('input[name$="[pages]"]').val()) || 0

      jobType = $(ol).find('select[name$="[print_job_type_id]"] :selected').val()
      oneSidedType = (
        jobsContainer.data('prices-one-sided')[jobType] || jobType
      )

      list = {}
      list[oneSidedType] = copies * (pages % 2)

      $(ol).data('oddPages', list)
      totalTypePages[jobType] += (copies * pages) || 0

    $('.order_line:not([data-exclude-from-total])').each (i, ol)->
      oddPages = $(ol).data('oddPages')

      for type, pages of oddPages
        totalTypePages = $('[data-jobs-container]').data('pages-list')
        totalTypePages[type] += pages

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
    
    # TODO Rectificar ya que no funciona el beforeunload para uploads
    @map.skipFileWarning ||= (e)->
      State.fileUploaded = false
      $(this).preventDefault()

    $(document).on 'click', '.skip-file-warning', @map.skipFileWarning
    $(document).on 'ajax:success', 'a.details-link', @map.showDocumentDetails
    $(document).on 'item.removed', @map.removeItem
    $(document).on 'change keyup', '.price-modifier, .page-modifier, .file_line_item',
      Order.updateAllOrderLines
    $(document).on 'click', 'a[data-action="print"]', @map.print
    
  unload: ->
    $(document).off 'click', '.skip-file-warning', @map.skipFileWarning
    $(document).off 'ajax:success', 'a.details-link', @map.showDocumentDetails
    $(document).off 'item.removed', @map.removeItem
    $(document).off 'change keyup', '.price-modifier, .page-modifier, .file_line',
      Order.updateAllOrderLines
    $(document).off 'click', 'a[data-action="print"]', @map.print

