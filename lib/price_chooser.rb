class PriceChooser
  include ActionView::Helpers::NumberHelper
  
  attr_accessor :copies
  
  def initialize(raw_setting, copies = 0)
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
  
  def parse
    @raw_setting.split(/\s*;\s*/).map do |rule|
      splited_rule = rule.split(/\s*@\s*/)
      condition = splited_rule.length > 1 ? splited_rule.shift : '%{c}'
      price = splited_rule.first
      
      condition.insert(0, '%{c} ') unless condition.include?('%{c}')
      
      [condition, price]
    end
  end
  
  def self.humanize
    %w{price_per_one_sided_copy price_per_two_sided_copy}.map do |price_type|
      price_chooser = self.new(Setting.send(price_type))
      rules = price_chooser.parse.map do |cond, price|
        if cond.match(/[><=]+\s*\.?\d+/)
          copies = cond.match(/\d+/)[0]
          rule_in_words = case cond.match(/[><=]+/)[0]
            when '>' then 'greater_than'
            when '>=' then 'greater_than_or_equal_to'
            when '=' then 'equal_to'
            when '<' then 'less_than'
            when '<=' then 'less_than_or_equal_to'
          end

          I18n.t(
            "view.settings.conditions.#{rule_in_words}",
            count: copies,
            price: price_chooser.number_to_currency(price.to_f)
          )
        else
          "*#{price_chooser.number_to_currency(price.to_f)}*"
        end
      end
      
      [I18n.t("view.settings.names.#{price_type}"), rules]
    end
  end
end