class PriceCalculator
  def self.final_job_price(options = {})
    rest = options[:total_pages] % 2
    even_pages = (options[:total_pages] - rest)

    if !rest.zero? && options[:type].two_sided
      one_sided_type = options[:type].one_sided_for
      copies = options[one_sided_type.try(:id)] || 1

      one_sided_price = PriceChooser.new(
        one_sided_type.try(:price) || options[:type].price, copies
      ).price
    end

    one_sided_price ||= 0.00

    if one_sided_price.zero?
      options[:total_pages] * options[:price_per_copy]
    else
      even_pages * options[:price_per_copy] + one_sided_price
    end
  end

  def self.price_per_copy(pj)
    total_pages = pj.print_total_pages

    if total_pages == 1 && pj.print_job_type.two_sided
      one_sided = pj.print_job_type.one_sided_for

      PriceChooser.new(
        one_sided.price, pj.print.try(:total_pages_by_type, one_sided)
      ).price
    else
      PriceChooser.new(pj.print_job_type.price, pj.print_total_pages).price
    end
  end
end
