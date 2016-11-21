new Rule
  condition: -> $('#ph_customers form').length
  load: ->
    @map.addShortCuts ||= (e)->
      key = e.which

      # CTRL + ALT + B = Agregar una bonificación
      if (key == 66 || key == 98) && e.ctrlKey && e.altKey
        # Mostrar si está oculto
        Helper.show $('#bonuses_section:hidden')

        $('#add_bonus_link').click()
        e.preventDefault()
        e.stopPropagation()

      # CTRL + ALT + D = Agregar un depósito
      if (key == 68 || key == 100) && e.ctrlKey && e.altKey
        $('#add_deposit_link').click()
        e.preventDefault()
        e.stopPropagation()

    $(document).on 'keydown', @map.addShortCuts

  unload: ->
    $(document).off 'keydown', @map.addShortCuts

new Rule
  condition: -> $('#ph_customers[data-action="show"]').length
  load: ->
    $('#month_select_to_pay').on 'change', ->
      window.location.href = window.location.href.replace(
        /date=([^&])+/, "date=#{$(this).val()}"
      )
      $(this).attr 'disabled', true

    $(document).on 'ajax:success', 'a[data-event="pay-debt"]', (xhr, data)->
      $(this).parents('section.nested_items').replaceWith(data)

