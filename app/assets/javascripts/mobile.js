jQuery(function() {
  if(navigator.userAgent.match(/mobile/i)) {
    $('.hidden_for_mobile').hide();
    
    $(document).on('click', '.toggle_display', function() {
      $($(this).attr('href')).toggle();
    });
  }
});