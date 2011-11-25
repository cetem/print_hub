# Mensajes (WOW)
window.Messages = {}

# Mantiene el estado de la aplicación
window.State =
  # Contador para generar un ID único
  newIdCounter: 0
  # Indicador de que alguna llamada por AJAX está en progreso
  ajaxInProgress: false

# Manejadores de eventos
window.EventHandler =
  # Agrega un ítem anidado
  addNestedItem: (e)->
    template = eval(e.data('template'))

    $(e.data('container')).append Util.replaceIds(template, /NEW_RECORD/g)

    e.trigger('item:added', e)

  # Oculta un elemento (agregado con alguna de las funciones para agregado
  # dinámico)
  hideItem: (e)->
    Helper.hide($(e).parents($(e).data('target')))

    $(e).prev('input[type=hidden].destroy').val('1')

    $(e).trigger('item:hidden', $(e))

  removeItem: (e)->
    target = e.parents(e.data('target'))

    Helper.remove target, -> $(document).trigger('item.removed', target)
  
  toggleMenu: (e)->
    target = $(e.data('target'))
    
    if target.is(':visible:not(:animated)')
      target.stop().fadeOut 300, ->
        $('span.arrow_up', e).removeClass('arrow_up').addClass('arrow_down')
      
      target.removeClass('hide_when_show_menu')
    else if target.is(':not(:animated)')
      $('.hide_when_show_menu').stop().hide()
      $(
        'span.arrow_up', $('#menu_links')
      ).removeClass('arrow_up').addClass('arrow_down')
      
      target.stop().fadeIn 300, ->
        $('span.arrow_down', e).removeClass('arrow_down').addClass('arrow_up')
      
      target.addClass 'hide_when_show_menu'

# Utilidades varias para asistir con efectos sobre los elementos
window.Helper =
  # Oculta el elemento indicado
  hide: (element, callback) -> $(element).stop().slideUp(500, callback)

  # Elimina el elemento indicado
  remove: (element, callback)->
    $(element).stop().slideUp 500, ->
      $(this).remove()
      
      callback() if jQuery.isFunction(callback)

  # Muestra el ítem indicado (puede ser un string con el ID o el elemento mismo)
  show: (element, callback)->
    e = $(element)

    e.stop().slideDown(500, callback) if e.is(':visible').length != 0

# Utilidades varias
window.Util =
  # Combina dos hash javascript nativos
  merge: (hashOne, hashTwo)-> jQuery.extend({}, hashOne, hashTwo)

  # Reemplaza todas las ocurrencias de la expresión regular 'regex' con un ID
  # único generado con la fecha y un número incremental
  replaceIds: (s, regex)->
    s.replace(regex, new Date().getTime() + State.newIdCounter++)

jQuery ($)->
  eventList = $.map EventHandler, (v, k) -> k
  
  # Para que los navegadores que no soportan HTML5 funcionen con autofocus
  $('*[autofocus]:not([readonly]):not([disabled]):visible:first').focus()
  
  $(document).on 'click', 'a[data-event]', (event)->
    return if event.stopped
    element = $(this)
    eventName = element.data('event')

    if $.inArray(eventName, eventList) != -1
      EventHandler[eventName](element)
      
      event.preventDefault()
      event.stopPropagation()

  $(document).on 'change', 'input.autocomplete_field', ->
    element = $(this)
    
    if /^\s*$/.test(element.val())
      element.next('input.autocomplete_id:first').val('')
  
  $('#loading_caption').bind
    ajaxStart: -> $(this).stop(true, true).slideDown(100)
    ajaxStop: -> $(this).stop(true, true).slideUp(100)
  
  $(document).bind
    ajaxStart: -> State.ajaxInProgress = true
    ajaxStop: -> State.ajaxInProgress = false
  
  $(document).on 'focus', 'input.calendar:not(.hasDatepicker)', ->
    if $(this).data('time')
      $(this).datetimepicker
        showOn: 'both',
        stepHour: 1,
        stepMinute: 5
      .focus()
    else
      $(this).datepicker
        showOn: 'both',
        onSelect: -> $(this).datepicker('hide')
      .focus()
  
  $(document).on 'click', 'input.file', ->
    $(this).parents('div.field:first').find('input[type="file"]').click()
  
  $('a.fancybox').fancybox(type: 'image')
  
  $(document).on 'click', 'a.show', (event)->
    $($(this).data('target')).stop(true, true).slideDown 300, ->
      $(this).find('*[autofocus]:not([readonly]):not([disabled]):visible:first').focus()
    
    event.preventDefault()
    event.stopPropagation()
  
  $('input[type="file"]').filestyle
    image: '/assets/choose-file.png',
    imageheight : 16,
    imagewidth : 16,
    width : 360
  
  $('form').submit ->
    $(this).find('input[type="submit"], input[name="utf8"]').attr(
      'disabled', true
    )
  
  # Verifica el estado de las llamadas AJAX antes de cerrar la ventana o
  # cambiar de página
  $(window).bind 'beforeunload', ->
    Messages.ajaxInProgressWarning if State.ajaxInProgress

# Lograr que la función click() se comporte de la misma manera que un click
if !HTMLAnchorElement.prototype.click
  HTMLAnchorElement.prototype.click = ->
    ev = document.createEvent 'MouseEvents'
    ev.initEvent 'click', true, true
    
    if this.dispatchEvent(ev) != false
      #safari will have already done this, but I'm not sniffing safari
      #just in case they might in the future fix it I figure it's better
      #to trigger the action twice than risk not triggering it at all
      document.location.href = this.href