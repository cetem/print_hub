class PriceChooser
  include ActionView::Helpers::NumberHelper

  attr_accessor :copies

  def initialize(raw_setting, copies = 0)
    @raw_setting = raw_setting
    @copies = copies
  end

  def price
    BigDecimal.new(
      parse.reverse.find { |cond, _price| eval(cond % { c: @copies }) }[1]
    )
  end

  def self.choose(*args)
    options = args.extract_options!
    total_copies = options[:copies] || 0
    price = PrintJobType.find(options[:type]).price

    new(price, total_copies).price
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
    PrintJobType.enabled.map do |print_job_type|
      type_price = new(print_job_type.price)
      rules = type_price.parse.map do |cond, price|
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
            "view.print_job_types.conditions.#{rule_in_words}",
            count: copies, type: print_job_type,
            price: type_price.number_to_currency(price.to_f)
          )
        else
          "*#{type_price.number_to_currency(price.to_f)}*"
        end
      end

      [
        I18n.t('view.print_job_types.price_per_copy', name: print_job_type),
        rules
      ]
    end
  end
end
