jQuery ->
  if $('#ph_stats').length > 0
    # Graphic calculations
    values = []
    labels = []
    container = $('#graph')
    width = container.innerWidth()

    $('table[data-graph-grid] tbody tr').each ->
      values.push parseInt($('td.value', this).text())
      labels.push $('td.label', this).text()

    Raphael(container.get(0), width, 500).pieChart(
      width / 2.0, 250, 175, values, labels, '#fff'
    )

    # Hide graphic
    $('#graph').hide()
    $('.show_grid').hide()

    $(document).on 'click', '.show_graph', ->
      $('table[data-graph-grid]').hide()
      $('.show_graph').hide()
      $('#graph').stop(true, true).fadeIn(300)
      $('.show_grid').show()

    $(document).on 'click', '.show_grid', ->
      $('#graph').hide()
      $('.show_grid').hide()
      $('table[data-graph-grid]').stop(true, true).fadeIn(300)
      $('.show_graph').show()