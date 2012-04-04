jQuery ->
  if $('#ph_documents').length > 0
    $(document).on 'click', 'a.add_link, a.remove_link', ->
      $(this).html('&#xe064;').attr('href', '#').click (event)->
        event.preventDefault()
      .removeAttr('data-remote').removeAttr('data-method').css('opacity', '.4')
    
    $(document).on 'change', '#document_code', ->
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
    
    $(document).on 'ajax:before', 'a.show_barcode', ->
      $(this).next('.barcode_container').stop(true, true).slideUp()
    
    $(document).on 'ajax:success', 'a.show_barcode', (xhr, data)->
      $(this).next('.barcode_container').html(data).stop(true, true).slideDown()
  
  if $('#ph_documents form').length > 0
    $('form').submit -> $('#notice').slideDown()

    $(document).keydown (e)->
      key = e.which

      # CTRL + ALT + E = Agregar una etiqueta
      if (key == 69 || key == 101) && e.ctrlKey && e.altKey
        $('#add_tag_link').click()
        e.preventDefault()
        e.stopPropagation()