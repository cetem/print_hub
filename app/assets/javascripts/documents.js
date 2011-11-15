jQuery(function() {
  if($('#ph_documents').length > 0) {
    $(document).on('click', 'a.add_link, a.remove_link', function() {
      $(this).html('X').attr('href', '#').click(function(event) {
        event.preventDefault();
      }).removeAttr('data-remote').removeAttr('data-method').css('opacity', '.4');
    });
    
    $(document).on('ajax:before', 'a.show_barcode', function() {
      $(this).next('.barcode_container').stop(true, true).slideUp();
      
      if(!/^\s*$/.test($('#document_code').val() || '')) {
        $(this).attr(
          'href',
          $(this).attr('href').replace(
            /[^/]*\/barcode/, $('#document_code').val() + '/barcode'
          )
        );
      }
    });
    
    $(document).on('ajax:success', 'a.show_barcode', function(xhr, data) {
      $(this).next('.barcode_container').html(data).stop(true, true).slideDown();
    });
  }
  
  if($('#ph_documents form').length > 0) {
    $('form').submit(function() { $('#notice').slideDown(); });

    $(document).keydown(function(e) {
      var key = e.which;

      // CTRL + ALT + E = Agregar una etiqueta
      if((key == 69 || key == 101) && e.ctrlKey && e.altKey) {
        $('#add_tag_link').click();
        e.preventDefault();
        e.stopPropagation();
      }
    });
  }
});