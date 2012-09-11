jQuery ($)->
  if $('#ph_stats').length > 0 && $('#graph').length > 0
    # Graphic calculations
    container = $('#graph')
    width = container.innerWidth()
    [values, labels] = [[], []]

    $('table[data-graph-grid] tbody tr').each ->
      values.push parseInt($(this).find('td[data-value-column]').text())
      labels.push "%%.%% #{$(this).find('td[data-label-column]').text()}"

    pie = Raphael(container.get(0), width, 500).piechart(
      width / 2.0, 250, 175, values,
      legend: labels,
      legendpos: 'east',
      legendothers: "%%.%% #{$('table[data-graph-grid]').data('othersLabel')}",
      stroke: '#efefef',
      strokewidth: 2
    )
    
    pie.hover ->
      this.sector.stop()
      this.sector.scale 1.1, 1.1, this.cx, this.cy

      if this.label
        this.label[0].stop()
        this.label[0].attr r: 7.5
        this.label[1].attr 'font-weight': 800
    , ->
      this.sector.animate transform: "s1 1 #{this.cx} #{this.cy}", 500, 'bounce'
      
      if this.label
        this.label[0].animate r: 5, 500, 'bounce'
        this.label[1].attr 'font-weight': 400
    
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
