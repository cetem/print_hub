jQuery(function() {  
  $(document).on('ajax:success', '#feedback a, #feedback form', function(event, data) {
    $('#feedback').html(data).find('textarea').focus();
  });
});