root = exports ? this # http://stackoverflow.com/questions/4214731/coffeescript-global-variables

class root.Inspector
  _instance = undefined

  @instance: -> _instance ?= new _Inspector

class _Inspector
  _rules: []
  _loadedRules: []

  _register: (rule) -> @_rules.push rule

  load: ->
    for i, rule of @_rules
      if rule.condition?()
        @_loadedRules.push rule
        rule.load()

  unload: ->
    rule.unload?() for i, rule of @_loadedRules

    @_loadedRules = []

  reload: -> @unload?(); @load()

class @Rule
  map: {}

  constructor: (attributes) ->
    @load = attributes.load
    @unload = attributes.unload
    @condition = attributes.condition || -> true

    throw 'The rule must have a load function' unless @load?

    Inspector.instance()._register(@)
