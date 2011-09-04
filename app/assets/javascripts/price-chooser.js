var PriceChooser = {
  choose: function(setting, copies) {
    var rules = PriceChooser.parse(setting + '');
    var price = 0;
    
    $.each(rules, function(i, e) {
      var useThis = eval(e[0].replace('%{c}', copies));
      
      if(useThis) { price = parseFloat(e[1]) || 0; }
    });
    
    return price;
  },

  parse: function(setting) {
    return $.map(setting.split(/\s*;\s*/), function(rule) {
      var splitedRule = rule.split(/\s*@\s*/);
      var condition = splitedRule.length > 1 ? splitedRule.shift() : '%{c}';
      var price = splitedRule[0] || '0';
      
      if(condition.indexOf('%{c}') == -1) {
        condition = '%{c} '.concat(condition);
      }
      
      return [[condition, price]]; // Map "aplana" los arrays WTF!
    });
  }
};