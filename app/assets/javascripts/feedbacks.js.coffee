jQuery ($)->
  $(document).on 'ajax:success', '.feedback a, .feedback form', (event, data)->
    $('.feedback').html(data).find('textarea').focus()