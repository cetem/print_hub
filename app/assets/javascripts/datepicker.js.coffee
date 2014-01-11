jQuery ($)->
  $(document).on 'focus keydown click', 'input[data-date-picker]', ->
    $(this).datepicker
      showOn: 'both',
      onSelect: -> $(this).datepicker('hide')
    .removeAttr('data-date-picker').focus()

  $(document).on 'focus keydown click', 'input[data-datetime-picker]', ->
    $(this).datetimepicker
      showOn: 'both',
      timeFormat: 'HH:mm',
      stepHour: 1,
      stepMinute: 5
    .removeAttr('data-datetime-picker').focus()

  # Due to a bug in jQuery UI, nasty hack...
  $(document).on 'page:change', ->
    $('.hasDatepicker').attr('data-date-picker', true)
      .datepicker('destroy').removeClass('hasDatepicker')

    $('.hasDatepicker').attr('data-datetime-picker', true)
      .datetimepicker('destroy').removeClass('hasDatepicker')

    $.datepicker.initialized = false
