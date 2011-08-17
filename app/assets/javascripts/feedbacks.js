jQuery(function() {  
  $('#feedback a, #feedback form').live('ajax:success', function(event, data) {
    $('#feedback').html(data).find('textarea').focus();
  });
});