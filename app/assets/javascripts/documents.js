jQuery(function() {
  if($('#ph_documents').length > 0) {
    $('a.add_link, a.remove_link').live('click', function() {
      $(this).html('X').attr('href', '#').click(function(event) {
        event.preventDefault();
      }).removeAttr('data-remote').removeAttr('data-method').css('opacity', '.4');
    });
    
    $('a.show_barcode').live('ajax:before', function() {
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
    
    $('a.show_barcode').live('ajax:success', function(xhr, data) {
      $(this).next('.barcode_container').html(data).stop(true, true).slideDown();
    });
  }
});