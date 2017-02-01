jQuery ($)->
  $(document).on 'click', '.toggle_display:not(.used)', ->
    id = $(this).attr 'href'
    wasVisible = $(id).is ':visible'

    $(this).after $('<div class="visible-phone"></div>').html($(id).html())
    $(this).addClass('used').hide()
    window.location.hash = if wasVisible then '' else 'mobile_content'
