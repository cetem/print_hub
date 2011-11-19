jQuery(function() {
  if($('#ph_customers form').length > 0) {
    $(document).keydown(function(e) {
      var key = e.which;

      // CTRL + ALT + E = Agregar una bonificación
      if((key == 66 || key == 98) && e.ctrlKey && e.altKey) {
        $('#add_bonus_link').click();
        e.preventDefault();
        e.stopPropagation();
      }

      // CTRL + ALT + D = Agregar un depósito
      if((key == 68 || key == 100) && e.ctrlKey && e.altKey) {
        $('#add_deposit_link').click();
        e.preventDefault();
        e.stopPropagation();
      }
    });
  }
  
  if($('#ph_customers[data-action="show"]').length > 0) {
    $(document).on('ajax:success', 'form[data-remote]', function(xhr, data) {
      $(this).parents('section.nested_items').replaceWith(data);
    });
  }
});