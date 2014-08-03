class CustomersGroup < ApplicationModel
  has_many :customers, foreign_key: 'group_id'

  validates :name, uniqueness: true, presence: true

  def to_s
    self.name
  end

  alias_method :label, :to_s

  def as_json(options = nil)
    default_options = {
      only: [:id],
      methods: [:label]
    }

    super(default_options.merge(options || {}))
  end

  def self.full_text(query_terms)
    options = text_query(query_terms, 'name')
    conditions = [options[:query]]

    where(
      conditions.map { |c| "(#{c})" }.join(' OR '), options[:parameters]
    ).order(options[:order])
  end

  def self.settlement_as_csv(start, finish)
    all.map { |cg| cg.settlement_as_csv(start, finish) }.join("\n\n")
  end

  def settlement_as_csv(start, finish)
    require 'csv'

    double_t    = I18n.t('view.customers_groups.double')
    simple_t    = I18n.t('view.customers_groups.simple')
    total_t     = I18n.t('view.customers_groups.total')
    total_price = 0.0
    range       = start..finish

    CSV.generate do |csv|

      csv << []
      csv << [self.name, simple_t, double_t, total_t]

      totals = { one_side: 0, two_sides: 0, library: 0.0 }

      customers.each do |c|
        copies = { one: 0, two: 0 }
        library = 0.0

        c.prints.where(created_at: range).each do |p|
          library += p.article_lines.map{ |a_l| a_l.units * a_l.unit_price }.sum

          copies[:one] += p.print_jobs.one_sided.sum(:printed_pages) || 0

          p.print_jobs.two_sided.each do |ts|
            if (ts.pages % 2) == 0
              copies[:two] += ts.printed_pages
            else
              copies[:one] += ts.copies
              copies[:two] += (ts.pages - 1) * ts.copies
            end
          end
        end

        totals[:one_side] += copies[:one]
        totals[:two_sides] += copies[:two]
        totals[:library] += library

        csv << [c.to_s, copies[:one], copies[:two], library]
      end

      csv << [nil, totals[:one_side], totals[:two_sides], totals[:library]] if customers.count > 1
    end
  end
end
