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
    e.trigger('item.added', e)

  # Oculta un elemento (agregado con alguna de las funciones para agregado
  # dinámico)
  hideItem: (e)->
    Helper.hide $(e).parents($(e).data('target'))
    $(e).prev('input[type=hidden].destroy').val('1').trigger 'item.hidden', $(e)

  removeItem: (e)->
    target = e.parents e.data('target')

    Helper.remove target, -> $(document).trigger('item.removed', target)

# Utilidades varias para asistir con efectos sobre los elementos
window.Helper =
  # Oculta el elemento indicado
  hide: (element, callback)-> $(element).stop().slideUp(500, callback)

  # Elimina el elemento indicado
  remove: (element, callback)->
    $(element).stop().slideUp 500, ->
      $(this).remove()
      callback() if jQuery.isFunction(callback)

  # Muestra el ítem indicado (puede ser un string con el ID o el elemento mismo)
  show: (e, callback)-> $(e).stop().slideDown(500, callback)

# Utilidades varias
window.Util =
  # Combina dos hash javascript nativos
  merge: (hashOne, hashTwo)-> $.extend({}, hashOne, hashTwo)

  # Reemplaza todas las ocurrencias de la expresión regular 'regex' con un ID
  # único generado con la fecha y un número incremental
  replaceIds: (s, regex)->
    s.replace(regex, new Date().getTime() + State.newIdCounter++)

jQuery ($)->
  eventList = $.map EventHandler, (v, k)-> k
  
  # Para que los navegadores que no soportan HTML5 funcionen con autofocus
  $('*[autofocus]:not([readonly]):not([disabled]):visible:first').focus()
  
  $('*[data-show-tooltip]').tooltip()
  
  $(document).on 'click', 'a[data-event]', (event)->
    return if event.stopped
    
    element = $(this)
    eventName = element.data('event')

    if $.inArray(eventName, eventList) != -1
      EventHandler[eventName](element)
      
      event.preventDefault()
      event.stopPropagation()
  
  $('#loading-caption').bind
    ajaxStart: `function() { $(this).stop(true, true).fadeIn(100) }`
    ajaxStop: `function() { $(this).stop(true, true).fadeOut(100) }`
    
  if $('.alert[data-close-after]').length > 0
    $('.alert[data-close-after]').each (i, a)->
      setTimeout(
        (-> $(a).find('a.close').trigger('click')), $(a).data('close-after')
      )
  
  $(document).bind
    ajaxStart: `function() { State.ajaxInProgress = true }`
    ajaxStop: `function() { State.ajaxInProgress = false }`
  
  $(document).on 'click', 'a[data-action="show"]', (event)->
    $($(this).data('target')).stop(true, true).slideDown 300, ->
      $(this).find('*[autofocus]:not([readonly]):not([disabled]):visible:first').focus()
    
    event.preventDefault()
    event.stopPropagation()
  
  $(document).on 'click', 'a[data-action="remove"]', (event)->
    Helper.remove($(this).data('target'))
    
    event.preventDefault()
    event.stopPropagation()
  
  $('form').submit ->
    $(this).find('input[type="submit"], input[name="utf8"]')
    .attr 'disabled', true
  
  # Verifica el estado de las llamadas AJAX antes de cerrar la ventana o
  # cambiar de página
  $(window).bind 'beforeunload', ->
    Messages.ajaxInProgressWarning if State.ajaxInProgress

# Lograr que la función click() se comporte de la misma manera que un click
if !HTMLAnchorElement.prototype.click
  HTMLAnchorElement.prototype.click = ->
    ev = document.createEvent 'MouseEvents'
    ev.initEvent 'click', true, true
    
    #safari will have already done this, but I'm not sniffing safari
    #just in case they might in the future fix it I figure it's better
    #to trigger the action twice than risk not triggering it at all
    document.location.href = this.href if this.dispatchEvent(ev) != false
