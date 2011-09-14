jQuery(function() {
  if($('#ph_documents').length > 0) {
    $('a.add_link, a.remove_link').live('click', function() {
      $(this).html('X').attr('href', '#').click(function(event) {
        event.preventDefault();
      }).removeAttr('data-remote').removeAttr('data-method').css('opacity', '.4');
    });
  }
});