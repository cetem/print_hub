new Rule
  condition: -> $('#ph_documents').length
  load: ->
    # Deshabilita el botón para agregar/quitar y lo cambia por un punto
    @map.disableAddOrRemoveFromOrder ||= ->
      $(this).html('&#xe064;').attr('href', '#').click (event)->
        event.preventDefault()
      .removeAttr('data-remote').removeAttr('data-method').css('opacity', '.4')

    # Cambia dinámicamente el link del código de barra al tipear
    @map.liveChangeBarcodeLink ||= ->
      if !/^\s*$/.test($('#document_code').val() || '')
        newShowHref = $('a.show_barcode').attr('href')
        .replace(/[^/]*\/barcode/, "#{$('#document_code').val()}/barcode")
        
        $('a.show_barcode').attr 'href', newShowHref
        
        newDownloadHref = $('a.download_barcode').attr('href')
        .replace(
          /[^/]*\/download_barcode/,
          "#{$('#document_code').val()}/download_barcode"
        )
        
        $('a.download_barcode').attr 'href', newDownloadHref

    # Oculta el código de barra
    @map.hideBarcodeContainer ||= ->
      $(this).next('.barcode_container').stop(true, true).slideUp()

    # Muestra el código de barra
    @map.showBarcodeContainer ||= (xhr, data)->
      $(this).next('.barcode_container').html(data).stop(true, true).slideDown()
  
    $(document).on 'change', '#document_code', -> @map.liveChangeBarcodeLink
    $(document).on 'ajax:before', 'a.show_barcode', -> @map.hideBarcodeContainer
    $(document).on 'ajax:success', 'a.show_barcode', @map.showBarcodeContainer
    $(document).on 'click', 'a.add_link, a.remove_link',
      @map.disableAddOrRemoveFromOrder

  unload: ->
    $(document).off 'change', '#document_code', -> @map.liveChangeBarcodeLink
    $(document).off 'ajax:before', 'a.show_barcode', -> @map.hideBarcodeContainer
    $(document).off 'ajax:success', 'a.show_barcode', @map.showBarcodeContainer
    $(document).off 'click', 'a.add_link, a.remove_link',
      @map.disableAddOrRemoveFromOrder

new Rule
  condition: -> $('#ph_documents form').length
  load: ->
    @map.addKeyShortcuts ||= (e)->
      key = e.which

      # CTRL + ALT + E = Agregar una etiqueta
      if (key == 69 || key == 101) && e.ctrlKey && e.altKey
        $('#add_tag_link').click()
        e.preventDefault()
        e.stopPropagation()

    $(document).on 'keydown', @map.addKeyShortcuts

  unload: ->
    $(document).off 'keydown', @map.addKeyShortcuts

