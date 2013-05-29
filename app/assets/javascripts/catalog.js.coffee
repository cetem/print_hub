new Rule
  condition: -> $('#ph_catalog').length
  load: ->
    # Deshabilita el botón para agregar/quitar y lo cambia por un punto
    @map.disableAddOrRemoveFromOrder ||= ->
      $(this).html('&#xe064;').attr('href', '#').click (event)->
        event.preventDefault()
      .removeAttr('data-remote').removeAttr('data-method').css('opacity', '.4')

    $(document).on 'click', 'a.add_to_order, a.remove_from_order',
      @map.disableAddOrRemoveFromOrder

  unload: ->
    $(document).off 'click', 'a.add_to_order, a.remove_from_order',
      @map.disableAddOrRemoveFromOrder
