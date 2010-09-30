// Mantiene el estado de la aplicación
var State = {
    // Contador para generar un ID único
    newIdCounter: 0
}

// Funciones de autocompletado
var AutoComplete = {
    observeAll: function() {
        $$('input.autocomplete').each(function(input) {
            if(!input.retrieve('observed')) {
                new Ajax.Autocompleter(
                    input,
                    input.adjacent('.autocomplete').first(),
                    input.readAttribute('data-autocomplete-url'),
                    {
                        paramName: 'q',
                        indicator: 'loading',
                        method: 'get',
                        afterUpdateElement: function(text, li) {
                            var objectId = $(li).id.strip().match(/(\d+)$/)[1];
                            var idField = input.adjacent('input.autocomplete_id');

                            idField.first().setValue(objectId);
                        }
                    }
                );

                input.store('observed', true);
            }
        });
    }
};

// Manejadores de eventos
var EventHandler = {
    eventList: $A([
        'addNestedItem',
        'hideItem',
        'removeItem'
    ]),

    /**
     * Agrega un ítem anidado
     */
    addNestedItem: function(e) {
        var template = eval(e.readAttribute('data-template'));

        $(e.readAttribute('data-container')).insert({
            bottom: Util.replaceIds(template, /NEW_RECORD/)
        });
    },

    /**
     * Oculta un elemento (agregado con alguna de las funciones para agregado
     * dinámico)
     */
    hideItem: function(e) {
        var target = e.readAttribute('data-target');

        Helper.hide(e.up(target));

        var hiddenInput = e.previous('input[type=hidden].destroy');

        if(hiddenInput) {hiddenInput.setValue('1');}
    },

    removeItem: function(e) {
        var target = e.readAttribute('data-target');
        
        Helper.remove(e.up(target));
    }
}

// Utilidades varias para asistir con efectos sobre los elementos
var Helper = {
    /**
     * Oculta el elemento indicado
     */
    hide: function(element, options) {
        Effect.SlideUp(element, Util.merge({duration: 0.5}, options));
    },

    /**
     * Oculta el elemento que indica que algo se está cargando
     */
    hideLoading: function(element) {
        $('loading').hide();

        if($(element)) {$(element).enable();}
    },

    /**
     * Elimina el elemento indicado
     */
    remove: function(element, options) {
        Effect.SlideUp(element, Util.merge({
            duration: 0.5,
            afterFinish: function() {$(element).remove();}
        }, options));
    },

    /**
     * Muestra el ítem indicado (puede ser un string con el ID o el elemento mismo)
     */
    show: function(element, options) {
        var e = $(element);

        if(e != null && !e.visible()) {
            Effect.SlideDown(e, Util.merge({duration: 0.5}, options));
        }
    },

    /**
     * Muestra una imagen para indicar que una operación está en curso
     */
    showLoading: function(element) {
        $('loading').show();

        if($(element)) {$(element).disable();}
    }
}

// Utilidades varias
var Util = {
    /**
     * Combina dos hash javascript nativos
     */
    merge: function(hashOne, hashTwo) {
        return $H(hashOne).merge($H(hashTwo)).toObject();
    },

    /**
     * Reemplaza todas las ocurrencias de la expresión regular 'regex' con un ID
     * único generado con la fecha y un número incremental
     */
    replaceIds: function(s, regex){
        return s.gsub(regex, new Date().getTime() + State.newIdCounter++);
    }
}

Event.observe(window, 'load', function() {
    document.on('click', 'a[data-remove]', function(event, element) {
        if (event.stopped) return;
        Helper.remove($(element.readAttribute('data-remove')));
        event.stop();
    });

    document.on('click', 'a[data-event]', function(event, element) {
        if (event.stopped) return;
        var eventName =
            element.readAttribute('data-event').dasherize().camelize();

        if(EventHandler.eventList.include(eventName)) {
            EventHandler[eventName](element);
            Event.stop(event);
        }
    });

    AutoComplete.observeAll();
});