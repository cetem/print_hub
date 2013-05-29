jQuery ($) ->
  $(document).on 'page:fetch', -> $('#loading_caption').show()
  $(document).on 'page:change', ->
    Inspector.instance().reload()
    $('#loading_caption').hide()
