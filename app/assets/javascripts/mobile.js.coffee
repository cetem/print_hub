jQuery ($)->
  if navigator.userAgent.match(/mobi|mini|fennec/i) && window.screen.width <= 800
    $('.hidden_for_mobile').hide().removeClass('hidden_for_mobile')
    
    $('#show_menu').on 'click', -> $('.hide_when_show_mobile_menu').hide()
    $('#hide_menu').on 'click', -> $('.hide_when_show_mobile_menu').show()
    
    $(document).on 'click', '.toggle_display', ->
      id = $(this).attr 'href'
      wasVisible = $(id).is ':visible'
      
      $(id).toggle()
      window.location.hash = if wasVisible then '' else id
    
    # Ocultar la barra de direcciones
    window.scrollTo(0, 1).delay 1000