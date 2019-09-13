@PriceChooser =
  choose: (setting, copies)->
    rules = PriceChooser.parse(setting + '')
    price = 0.0

    $.each rules, (i, e)->
      useThis = eval(e[0].replace('%{c}', copies))
      price = parseFloat(e[1]) || 0.0 if useThis

    price

  parse: (setting)->
    $.map setting.split(/\s*;\s*/), (rule)->
      splitedRule = rule.split(/\s*@\s*/)
      condition = if splitedRule.length > 1 then splitedRule.shift() else '%{c}'
      price = splitedRule[0] || '0'

      condition = '%{c} '.concat(condition) if condition.indexOf('%{c}') == -1

      [[condition, price]] # Map "aplana" los arrays WTF!
