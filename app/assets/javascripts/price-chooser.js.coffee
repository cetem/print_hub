@PriceChooser =
  choose: (setting, copies, withoutDiscounts)->
    rules = PriceChooser.parse(setting + '', withoutDiscounts)
    price = 0.0

    $.each rules, (i, e)->
      useThis = eval(e[0].replace('%{c}', copies))
      price = parseFloat(e[1]) || 0.0 if useThis

    price

  parse: (setting, withoutDiscounts)->
    parsedRules = _.map setting.split(/\s*;\s*/), (rule)->
      splitedRule = rule.split(/\s*@\s*/)
      condition = if splitedRule.length > 1 then splitedRule.shift() else '%{c}'
      price = splitedRule[0] || '0'

      condition = '%{c} '.concat(condition) if condition.indexOf('%{c}') == -1

      [condition, price]

    if withoutDiscounts
      [_.last(_.sortBy parsedRules, (rule) -> parseFloat(rule[1]))]
    else
      parsedRules
