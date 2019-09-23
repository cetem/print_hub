module PriceCalculator
  extend self

  def final_job_price(options = {})
    rest = options[:pages] % 2
    even_pages = (options[:pages] - rest)

    if !rest.zero? && options[:type].two_sided
      one_sided_type = options[:type].one_sided_for
      copies = options[one_sided_type.try(:id)] || 1

      one_sided_price = ::PriceChooser.new(
        one_sided_type.try(:price) || options[:type].price, copies
      ).price
    end

    one_sided_price ||= 0.00

    partial_price = if one_sided_price.zero?
                      options[:pages] * options[:price_per_copy]
                    else
                      even_pages * options[:price_per_copy] + one_sided_price
                    end

    options[:copies] * partial_price
  end

  def price_per_copy(line)
    total_pages = line.print_total_pages
    one_sided = line.print_job_type.one_sided_for

    if total_pages == 1 && line.print_job_type.two_sided && one_sided
      ::PriceChooser.new(
        one_sided.price, line.usable_parent.try(:total_pages_by_type, one_sided)
      ).price
    else
      ::PriceChooser.new(
        line.print_job_type.price, line.print_total_pages,
        without_discounts: line.usable_parent.try(:without_discounts)
      ).price
    end
  end
end
