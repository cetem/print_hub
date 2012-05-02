$(document).on 'focus', 'input[data-date-picker]:not(.hasDatepicker)', ->
  $(this).datepicker
    showOn: 'both',
    onSelect: -> $(this).datepicker('hide')
  .focus()
  
$(document).on 'focus', 'input[data-datetime-picker]:not(.hasDatepicker)', ->
  $(this).datetimepicker
    showOn: 'both',
    stepHour: 1,
    stepMinute: 5
  .focus()