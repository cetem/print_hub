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

  def price_per_copy(pj)
    total_pages = pj.print_total_pages
    one_sided = pj.print_job_type.one_sided_for

    if total_pages == 1 && pj.print_job_type.two_sided && one_sided
      ::PriceChooser.new(
        one_sided.price, pj.print.try(:total_pages_by_type, one_sided)
      ).price
    else
      ::PriceChooser.new(pj.print_job_type.price, pj.print_total_pages).price
    end
  end
end
