jQuery(function() {
  if(navigator.userAgent.match(/mobile/i)) {
    $('.hidden_for_mobile').hide();
    
    $('.toggle_display').live('click', function() {
      $($(this).attr('href')).toggle();
    });
  }
});