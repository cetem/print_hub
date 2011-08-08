jQuery(function() {
  $('a.add_to_order, a.remove_from_order').live('click', function() {
    $(this).html('#').attr('href', '#').click(function(event) {
      event.preventDefault();
    }).removeAttr('data-remote').removeAttr('data-method').css('opacity', '.4');
  });
});