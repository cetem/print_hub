// Mantiene el estado de la aplicación
var State = {
  // Contador para generar un ID único
  newIdCounter: 0
}

// Funciones de autocompletado
var AutoComplete = {
  observeAll: function() {
    $('input.autocomplete_field:not([data-observed])').each(function(){
      var input = $(this);
      
      input.autocomplete({
        source: function(request, response) {
          return jQuery.ajax({
            url: input.data('autocompleteUrl'),
            dataType: 'json',
            data: {q: request.term},
            success: function(data) {
              response(jQuery.map(data, function(item) {
                  var content = $('<div>');
                  
                  content.append($('<span class="label">').text(item.label));
          
                  if(item.informal) {
                    content.append($('<span class="informal">').text(item.informal));
                  }

                  return {label: content.html(), value: item.label, item: item};
                })
              );
            }
          });
        },
        type: 'get',
        select: function(event, ui) {
          var selected = ui.item;
          
          input.val(selected.value);
          input.data('item', selected.item);
          input.next('input.autocomplete_id').val(selected.item.id);
          
          input.trigger('autocomplete:update', input);
          
          return false;
        },
        open: function() { $('.ui-menu').css('width', input.width()); }
      });
      
      input.data('autocomplete')._renderItem = function(ul, item) {
        return $('<li></li>')
          .data('item.autocomplete', item)
          .append($( "<a></a>" ).html(item.label)).appendTo( ul );
      }
    }).data('observed', true);
  }
};

// Manejadores de eventos
var EventHandler = {
  /**
     * Agrega un ítem anidado
     */
  addNestedItem: function(e) {
    var template = eval(e.data('template'));

    $(e.data('container')).append(Util.replaceIds(template, /NEW_RECORD/g));

    e.trigger('item:added', e);
  },

  /**
     * Oculta un elemento (agregado con alguna de las funciones para agregado
     * dinámico)
     */
  hideItem: function(e) {
    Helper.hide($(e).parents($(e).data('target')));

    $(e).prev('input[type=hidden].destroy').val('1');

    $(e).trigger('item:hidden', $(e));
  },

  removeItem: function(e) {
    var target = e.parents(e.data('target'));

    Helper.remove(target);

    target.trigger('item:removed', target);
  },
  
  toggleMenu: function(e) {
    var target = $(e.data('target'));
    
    if(target.is(':visible:not(:animated)')) {
      target.stop().slideUp(300);
      
      target.removeClass('hide_when_show_menu');
    } else if (target.is(':not(:animated)')) {
      $('.hide_when_show_menu').stop().hide();
      
      target.stop().slideDown(300);
      
      target.addClass('hide_when_show_menu');
    }
  }
}

// Utilidades varias para asistir con efectos sobre los elementos
var Helper = {
  /**
     * Oculta el elemento indicado
     */
  hide: function(element, callback) {
    $(element).stop().slideUp(500, callback);
  },

  /**
     * Oculta el elemento que indica que algo se está cargando
     */
  hideLoading: function(element) {
    $('#loading_image').hide();

    $(element).attr('disabled', false);
  },

  /**
     * Elimina el elemento indicado
     */
  remove: function(element, callback) {
    $(element).stop().slideUp(500, function() {
      $(this).remove();
      
      if(jQuery.isFunction(callback)) { callback(); }
    });
  },

  /**
     * Muestra el ítem indicado (puede ser un string con el ID o el elemento mismo)
     */
  show: function(element, callback) {
    var e = $(element);

    if(e.is(':visible').length != 0) {
      e.stop().slideDown(500, callback);
    }
  },

  /**
     * Muestra una imagen para indicar que una operación está en curso
     */
  showLoading: function(element) {
    $('#loading_image').show();

    if( $(element).is(':visible')) { $(element).attr('disabled', true); }
  }
}

// Utilidades varias
var Util = {
  /**
     * Combina dos hash javascript nativos
     */
  merge: function(hashOne, hashTwo) {
    return jQuery.extend({}, hashOne, hashTwo);
  },

  /**
     * Reemplaza todas las ocurrencias de la expresión regular 'regex' con un ID
     * único generado con la fecha y un número incremental
     */
  replaceIds: function(s, regex){
    return s.replace(regex, new Date().getTime() + State.newIdCounter++);
  }
}

jQuery(function($) {
  var eventList = $.map(EventHandler, function(v, k ) {return k;});
  
  // Para que los navegadores que no soportan HTML5 funcionen con autofocus
  $('*[autofocus]:visible:first').focus();
  
  $('a[data-event]').live('click', function(event) {
    if (event.stopped) return;
    var element = $(this);
    var eventName = element.data('event');

    if($.inArray(eventName, eventList) != -1) {
      EventHandler[eventName](element);
      
      event.preventDefault();
      event.stopPropagation();
    }
  });

  $('input.autocomplete_field').live('change', function() {
    var element = $(this);
    
    if(/^\s*$/.test(element.val())) {
      element.next('input.autocomplete_id:first').val('');
    }
  });
  
  $('#loading_image').bind({
    ajaxStart: function() {$(this).show();},
    ajaxStop: function() {$(this).hide();}
  });
  
  $('input.calendar:not(.hasDatepicker)').live('focus', function() {
    if($(this).data('time')) {
      $(this).datetimepicker({showOn: 'both'}).focus();
    } else {
      $(this).datepicker({showOn: 'both'}).focus();
    }
  });

  AutoComplete.observeAll();
});

// Lograr que la función click() se comporte de la misma manera que un click
if (!HTMLAnchorElement.prototype.click) {
  HTMLAnchorElement.prototype.click = function() {
    var ev = document.createEvent('MouseEvents');
    ev.initEvent('click',true,true);
    if (this.dispatchEvent(ev) !== false) {
      //safari will have already done this, but I'm not sniffing safari
      //just in case they might in the future fix it; I figure it's better
      //to trigger the action twice than risk not triggering it at all
      document.location.href = this.href;
    }
  }
}