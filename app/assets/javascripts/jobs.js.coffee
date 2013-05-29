@Jobs =
  listenRangeChanges: (itemClass)->
    $(document).on 'keyup', 'input[name$="[range]"]', ->
      element = $(this)
      [validRanges, maxPage, rangePages] = [true, null, 0]
      pages = parseInt element.parents(itemClass).find('input[name$="[pages]"]').val()
      ranges = element.val().trim().split(/\s*,\s*/).sort (r1, r2)->
        r1Value = parseInt(r1.match(/^\d+/)) || 0
        r2Value = parseInt(r2.match(/^\d+/)) || 0

        r1Value - r2Value

      $.each ranges, (i, r)->
        data = r.match /^(\d+)(-(\d+))?$/
        n1 = parseInt(data[1]) if data
        n2 = parseInt(data[3]) if data

        validRanges = validRanges && n1 && n1 > 0 && (!n2 || n1 < n2)
        validRanges = validRanges && (!maxPage || maxPage < n1)

        maxPage = n2 || n1
        rangePages += if n2 then n2 + 1 - n1 else 1

      if (/^\s*$/.test(element.val()) || validRanges) && (!pages || !maxPage || pages >= maxPage)
        element.parents('.control-group').removeClass('error')

        if /^\s*$/.test(element.val()) && pages
          element.data('rangePages', pages).trigger('change')
        else if !/^\s*$/.test(element.val()) && validRanges
          element.data('rangePages', rangePages).trigger('change')
      else
        element.parents('.control-group').addClass('error')
  
  listenPrintJobTypeChanges: (itemClass)->
    $(document).on 'change', 'select[name$="[print_job_type_id]"]', ->
      Jobs.updatePricePerCopy(itemClass)
  
  updatePricePerCopy: (itemClass)->
    $('[data-jobs-container] span.money').each (i, ppc)->
      row = $(ppc).parents('.print_job, .order_line').first()

      if (dataTypeId = row.find('select[name$="[print_job_type_id]"] :selected'))
        dataTypeId = dataTypeId.val()

        jobsContainer = $('[data-jobs-container]')
        setting = jobsContainer.data('prices-list')[dataTypeId]
        typePages = jobsContainer.data('pages-list')[dataTypeId] || 0

        newPricePerCopy = PriceChooser.choose(setting, typePages).toFixed(3)

        newTitle = $(ppc).attr('title').replace(
          /(\d+\.\d+)$/, newPricePerCopy
        )

        row.data('price-per-copy', newPricePerCopy)
        $(ppc).attr('title', newTitle)
