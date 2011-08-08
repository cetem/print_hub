jQuery(function() {
  $('a.add_to_order, a.remove_from_order').live('click', function() {
    $(this).die().html('&nbsp;');
  });
});