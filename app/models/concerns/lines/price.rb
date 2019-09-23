module Lines::Price
  extend ActiveSupport::Concern

  included do
    after_initialize :lines_price_default_values

    def lines_price_default_values
      self.pages  ||= 0
      self.copies ||= 1
    end
  end

  def price
    total_price = ::PriceCalculator.final_job_price(
      (usable_parent.try(:pages_per_type) || {}).merge(
        price_per_copy: job_price_per_copy,
        type:           self.print_job_type,
        pages:          self.range_pages,
        copies:         self.copies
      )
    )

    self.total_price = total_price if respond_to?(:total_price=)

    total_price
  end

  def job_price_per_copy
    ::PriceCalculator.price_per_copy(self)
  end

  def print_total_pages
    usable_parent.try(:total_pages_by_type, self.print_job_type) || 0
  end

  def total_pages
    self.pages * self.copies
  end

  def usable_parent
    print # by default
  end

  def range_pages
    pages
  end
end
