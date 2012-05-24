window.Order =
  updateTotalPrice: ->
    totalPrice = 0.0
    credit = parseFloat($('#user').data('credit')) || 0
    
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
    Jobs.updatePricePerCopy()
    
    copies = parseInt orderLine.find('input[name$="[copies]"]').val()
    pages = parseInt orderLine.find('input[name$="[pages]"]').val()
    pricePerCopy = parseFloat(
      orderLine.find('input[name$="[price_per_copy]"]').val()
    )
    pricePerOneSidedCopy = PriceChooser.choose(
      $('#total_pages').data('pricePerOneSided'), parseInt($('#total_pages').val())
    )
    evenRange = pages - (pages % 2)
    rest = (pages % 2) * pricePerOneSidedCopy
    olPrice = (copies * (pricePerCopy * evenRange + rest)) || 0
    money = orderLine.find('span.money')

    orderLine.data 'price', olPrice.toFixed(3)
    money.html(money.html().replace(/(\d+.)+\d+/, olPrice.toFixed(3)))

    Order.updateTotalPrice()

jQuery ($)->
  if $('#ph_orders').length > 0
    $(document).on 'ajax:success', 'a.details-link', (event, data)->
      Helper.show(
        $(this).parents('.order_line').find('.dynamic_details').hide().html(data)
      )

    $(document).on 'item.removed', (event, element)->
      if $(element).hasClass('order_line')
        $(element).attr('data-exclude-from-total', '1')
        .find('.page-modifier:first').trigger('ph.page_modification')

        Order.updateTotalPrice()

    Jobs.listenTwoSidedChanges()

    $(document).on 'change keyup', '.price-modifier', ->
      Order.updateOrderLinePrice $(this).parents('.order_line')

    $(document).on 'change keyup ph.page_modification', '.page-modifier', ->
      totalPages = 0

      $('.order_line').each ->
        copies = parseInt $(this).find('input[name$="[copies]"]').val()
        pages = parseInt $(this).find('input[name$="[pages]"]').val()

        totalPages += (copies || 0) * (pages || 0)

      $('#total_pages').val totalPages
      $('.order_line').each -> Order.updateOrderLinePrice($(this))