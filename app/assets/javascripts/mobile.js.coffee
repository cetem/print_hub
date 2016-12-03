jQuery ($)->
  $(document).on 'click', '.toggle_display:not(.used)', ->
    id = $(this).attr 'href'
    wasVisible = $(id).is ':visible'

    $(this).after $('<div class="visible-phone"></div>').html($(id).html())
    $(this).addClass('used').hide()
    window.location.hash = if wasVisible then '' else 'mobile_content'

  if navigator.userAgent.match(/mobi|mini|fennec/i)
    # Ocultar la barra de direcciones
    window.scrollTo(0, 1).delay 1000
