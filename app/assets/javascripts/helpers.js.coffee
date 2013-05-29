# Mensajes (WOW)
@Messages = {}

# Mantiene el estado de la aplicación
@State =
  # Contador para generar un ID único
  newIdCounter: 0
  # Indicador de que alguna llamada por AJAX está en progreso
  ajaxInProgress: false
  # Indicador de que se han subido archivos
  fileUploaded: false

# Manejadores de eventos
@EventHandler =
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
@Helper =
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
@Util =
  # Combina dos hash javascript nativos
  merge: (hashOne, hashTwo)-> $.extend({}, hashOne, hashTwo)

  # Reemplaza todas las ocurrencias de la expresión regular 'regex' con un ID
  # único generado con la fecha y un número incremental
  replaceIds: (s, regex)->
    s.replace(regex, new Date().getTime() + State.newIdCounter++)


