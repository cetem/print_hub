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

      total_copies = { one: 0, two: 0 }

      customers.each do |c|
        copies = { one: 0, two: 0 }

        c.prints.where(created_at: range).each do |p|

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

        total_copies[:one] += copies[:one]
        total_copies[:two] += copies[:two]

        csv << [c.to_s, copies[:one], copies[:two]]
      end

      csv << [nil, total_copies[:one], total_copies[:two]] if customers.count > 1
    end
  end
end
