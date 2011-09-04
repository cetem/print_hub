class PriceChooser
  def initialize(raw_setting, copies)
    @raw_setting, @copies = raw_setting, copies
  end
  
  def price
    BigDecimal.new(
      parse.select {|cond, price| eval(cond % { c: @copies }) }.last[1]
    )
  end
  
  def self.choose(*args)
    options = args.extract_options!
    copies = options[:copies] || 0
    
    if options[:one_sided]
      self.new(Setting.price_per_one_sided_copy, copies).price
    else
      self.new(Setting.price_per_two_sided_copy, copies).price
    end
  end
  
  private
  
  def parse
    @raw_setting.split(/\s*;\s*/).map do |rule|
      splited_rule = rule.split(/\s*@\s*/)
      condition = splited_rule.length > 1 ? splited_rule.shift : '%{c}'
      price = splited_rule.first
      
      condition.insert(0, '%{c} ') unless condition.include?('%{c}')
      
      [condition, price]
    end
  end
end