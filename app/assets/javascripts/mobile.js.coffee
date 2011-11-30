jQuery ->
  if navigator.userAgent.match(/mobile/i)
    $('.hidden_for_mobile').hide()
    
    # Ocultar la barra de direcciones
    window.scrollTo(0, 1).delay 1000
        
    $(document).on 'click', '.toggle_display', ->
      $($(this).attr('href')).toggle()