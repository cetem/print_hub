jQuery ->
  if navigator.userAgent.match(/mobile/i)
    $('.hidden_for_mobile').hide()
    
    $(document).on 'click', '.toggle_display', ->
      $($(this).attr('href')).toggle()