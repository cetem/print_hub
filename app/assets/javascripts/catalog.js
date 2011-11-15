jQuery(function() {
  if($('#ph_catalog').length > 0) {
    $(document).on('click', 'a.add_to_order, a.remove_from_order', function() {
      $(this).html('X').attr('href', '#').click(function(event) {
        event.preventDefault();
      }).removeAttr('data-remote').removeAttr('data-method').css('opacity', '.4');
    });
  }
});