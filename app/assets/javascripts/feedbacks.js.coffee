new Rule
  condition: -> $('.feedback').length
  load: ->
    @map.showRespondFeedback ||= (event, data)->
      $('.feedback').html(data).find('textarea').focus()

    $(document).on 'ajax:success', '.feedback a, .feedback form',
      @map.showRespondFeedback

  unload: ->
    $(document).off 'ajax:success', '.feedback a, .feedback form',
      @map.showRespondFeedback
