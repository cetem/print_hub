new Rule
  load: ->
    # For browsers with no autofocus support
    $('[autofocus]:not([readonly]):not([disabled]):visible:first').focus()
    $('[data-show-tooltip]').tooltip()

    timers = @map.timers = []

    $('.alert[data-close-after]').each (i, a)->
      timers.push setTimeout((-> $(a).alert('close')), $(a).data('close-after'))

  unload: ->
    clearTimeout timer for i, timer of @map.timers

new Rule
  condition: -> $('.js-upload-file').length
  load: ->
    @map.addUploadFileEventToButtom ||= (e)->
      e.preventDefault()
      e.stopPropagation()

      $('.js-uploader-input').click()

    # Subir un archivo
    error_div = document.querySelector('.js-file-upload-error')
    progress_div = document.querySelector('.progress.hide')
    $('.js-uploader-input').fileupload
      dataType: 'script'
      add: (e, data) ->
        type = /(pdf)$/i
        file = data.files[0]

        if type.test(file.type) || type.test(file.name)
          $('input:submit').attr('disabled', true)
          error_div.style.display = 'none'
          progress_div.style.display = 'block'
          data.submit()
        else
          error_div.innerHTML = error_div.getAttribute('data-wrong-format')
          error_div.style.display = 'block'

      progressall: (e, data) ->
        error_div.style.display = 'none'
        progress_div.style.display = 'block'
        progress = parseInt(data.loaded / data.total * 100, 10)
        $('.progress .bar').css('width', progress + '%')

      done: (e, data) ->
        progress_div.style.display = 'none'
        $('input:submit').attr('disabled', false)
        State.fileUploaded = true
        # File line for prints
        file_line = $('.file_line_item:last')
        if file_line
          file_line.find('.price-modifier').change()
      error: (e) ->
        progress_div.style.display = 'none'
        error_div.innerHTML = error_div.getAttribute('data-broken-pdf')
        error_div.style.display = 'block'

    $(document).on 'click', '.js-upload-file', @map.addUploadFileEventToButtom

  unload: ->
    $(document).off 'click', '.js-upload-file', @map.addUploadFileEventToButtom


jQuery ($)->
  # Envía el formulario si en vez de un botón creamos un link-submit
  $(document).on 'click', 'a.submit', -> $('form').submit(); false

  # Muestra/esconde el cartel _cargando_ y activa/desactiva el _ajaxInProgress_
  $(document).on
    ajaxStart: ->
      $('#loading_caption').stop(true, true).fadeIn(100)
      State.ajaxInProgress = true
    ajaxStop: ->
      $('#loading_caption').stop(true, true).fadeOut(100)
      State.ajaxInProgress = false

  # Activa un evento dependiendo del data-event
  $(document).on 'click', 'a[data-event]', (event)->
    return if event.stopped

    element = $(this)
    eventName = element.data('event')
    eventList = $.map EventHandler, (v, k)-> k

    if $.inArray(eventName, eventList) != -1
      EventHandler[eventName](element)

      event.preventDefault()
      event.stopPropagation()

  # Muestra dinámicamente con efecto
  $(document).on 'click', 'a[data-action="show"]', (event)->
    $($(this).data('target')).stop(true, true).slideDown 300, ->
      $(this).find(
        '*[autofocus]:not([readonly]):not([disabled]):visible:first'
      ).focus()

    event.preventDefault()
    event.stopPropagation()

  # Remueve con efecto el elemento eliminado
  $(document).on 'click', 'a[data-action="remove"]', (event)->
    Helper.remove($(this).data('target'))

    event.preventDefault()
    event.stopPropagation()

  # Desactiva el botón submit al darle click
  $(document).on 'submit', 'form', ->
    $(this).find('input[type="submit"], input[name="utf8"]').attr 'disabled', true
    $(this).find('a.submit').removeClass('submit').addClass('disabled')
    $(this).find('.dropdown-toggle').addClass('disabled')


  # Carga el Inspector de eventos para turbolinks
  Inspector.instance().load()
