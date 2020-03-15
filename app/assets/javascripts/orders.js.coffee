@Order =
  updateTotalPrice: ->
    totalPrice = 0.0
    credit = parseFloat($('#user').data('credit')) || 0

    total_price = 0.0
    _.each Jobs.getPrintableJobs(), (order)->
      job = Jobs.assignDefaultOrGetJob(order)
      totalPrice += if job then job.price else 0.0

    # TODO: DEFINE WHATEVER WE WANT (temporal fix)
    $('#printed').hide()
    $('.js-scheduled-at').hide()
    $('#not_printed').show()

    money = $('#total span.money')

    money.html(money.html().replace(/(\d+.)+\d+/, totalPrice.toFixed(3)))

  updateOrderLinePrice: (orderLine)->
    #Order.updateTotalPages()
    Jobs.reCalcPages(orderLine[0])


    # orderLinesContainer = $('.jobs-container')
    # mediaType = orderLine.find(
    #   'select[name$="[print_job_type_id]"] :selected'
    # ).val()

    # copies = parseInt(orderLine.find('input[name$="[copies]"]').val())
    # pages = parseInt(orderLine.find('input[name$="[pages]"]').val())
    # evenPages = pages - (pages % 2)
    # rest = (pages % 2)

    # pricePerCopy = orderLine.data('price-per-copy')
    # oneSidedType = orderLinesContainer.data('odd-pages-types')[mediaType] || mediaType
    # oneSidedSettings = orderLinesContainer.data('prices-list')[oneSidedType]
    # mediaPages = orderLinesContainer.data('pages-list')[mediaType]

    # oneSidedPages = if rest then mediaPages || rest else 0
    # pricePerOneSidedCopy = PriceChooser.choose(
    #   oneSidedSettings, parseInt(oneSidedPages)
    # )
    # jobPrice = parseFloat(
    #   copies * (pricePerCopy * evenPages + pricePerOneSidedCopy) || 0
    # ).toFixed(3)

    # money = orderLine.find('span.money')
    # orderLine.data('price', jobPrice)
    # money.html(money.html().replace(/(\d+.)+\d+/, jobPrice))

    Order.updateTotalPrice()

  updateTotalPages: ->
    jobsContainer = $('.jobs-container')
    totalTypePages = jobsContainer.data('pages-list')

    # Reset the counts
    $.each totalTypePages, (key, value) ->
      totalTypePages[key] = 0

    $('.order_line:not(.exclude-from-total)').each (i, ol)->
      copies = parseInt $(ol).find('input[name$="[copies]"]').val()
      pages = parseInt($(ol).find('input[name$="[pages]"]').val()) || 0

      jobType = $(ol).find('select[name$="[print_job_type_id]"] :selected').val()
      oneSidedType = (
        jobsContainer.data('odd-pages-types')[jobType] || jobType
      )

      list = {}
      list[oneSidedType] = copies * (pages % 2)

      $(ol).data('oddPages', list)
      totalTypePages[jobType] += (copies * pages) || 0

    $('.order_line:not(.exclude-from-total)').each (i, ol)->
      oddPages = $(ol).data('oddPages')

      for type, pages of oddPages
        totalTypePages = $('[data-jobs-container]').data('pages-list')
        totalTypePages[type] += pages

  updateAllOrderLines: ->
    $('.order_line:not(.exclude-from-total)').each ->
      #Order.updateTotalPages()
      Order.updateOrderLinePrice $(this)


new Rule
  condition: -> $('#ph_orders #check_order').length
  load: ->
    Jobs.loadPricesData()
    Jobs.reCalcEverything()

    # Actualizar precios
    Order.updateAllOrderLines()

    $(document).on 'autocomplete:update', 'input.autocomplete-field', ->
      item = $(this).data('item')

      if item.pages
        pages = item.pages
        stock = parseInt(item.stock)
        line = $(this).parents('.js-printable-job:first')[0]
        lineDetailsLink = line.querySelector('a.details-link')
        lineStockDetails = line.querySelector('.document_stock')

        jobStorage = Jobs.assignDefaultOrGetJob(line)
        jobStorage.rangePages = pages

        pagesInput = line.querySelector('input[name$="[pages]"]')
        pagesInput.value = pages
        pagesInput.disabled = true

        Util.replaceOwnAttrWithRegEx(lineDetailsLink, 'href', /\d+$/, item.id)
        Helper.show(lineDetailsLink)


        if item.print_job_type_id
          line.querySelector('.js-print_job_type-selector').value = item.print_job_type_id

        Jobs.reCalcPages(line)

      Jobs.reCalcEverything()

    $(document).on 'change keyup',  '.price-modifier', ->
      Util.debounce(
        Jobs.reCalcPages($(this).parents('.order_line:first')[0])
      )

    # Mostrar detalles del documento
    @map.showDocumentDetails ||= (event, data)->
      Helper.show(
        $(this).parents('.order_line').find('.dynamic_details').hide().html(data)
      )

    # Eliminar item de la orden
    @map.removeItem ||= (event, element)->
      if $(element).hasClass('order_line')
        element.classList.add('exclude-from-total')
        Order.updateTotalPrice()


    # TODO Rectificar ya que no funciona el beforeunload para uploads
    @map.skipFileWarning ||= (e)->
      State.fileUploaded = false
      $(this).preventDefault()

    #$(document).on 'click', '.skip-file-warning', @map.skipFileWarning
    $(document).on 'ajax:success', 'a.details-link', @map.showDocumentDetails
    $(document).on 'item.removed', @map.removeItem
    $(document).on 'change keyup', '.price-modifier, .page-modifier, .file_line_item',
      Order.updateAllOrderLines

  unload: ->
    #$(document).off 'click', '.skip-file-warning', @map.skipFileWarning
    $(document).off 'ajax:success', 'a.details-link', @map.showDocumentDetails
    $(document).off 'item.removed', @map.removeItem
    $(document).off 'change keyup', '.price-modifier, .page-modifier, .file_line',
      Order.updateAllOrderLines

