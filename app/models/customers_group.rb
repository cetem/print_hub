class CustomersGroup < ApplicationModel
  has_many :customers, foreign_key: 'group_id'

  validates :name, uniqueness: true, presence: true

  def to_s
    name
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

  def self.settlement_as_csv(start = 1.year.ago, finish = Time.zone.now)
    _group = []

    all.each do |cg|
      _group += cg.settlement_as_csv(start, finish)
    end

    _group
  end

  def settlement_as_csv(start = 1.year.ago, finish = Time.zone.now)
    double_t    = I18n.t('view.customers_groups.double')
    simple_t    = I18n.t('view.customers_groups.simple')
    library_t   = I18n.t('view.customers_groups.library')
    total_t     = I18n.t('view.customers_groups.total')
    range       = start..finish

    csv = []
    csv << []
    csv << [name, simple_t, double_t, library_t, total_t]

    totals = { one_side: 0, two_sides: 0, library: 0.0 }

    customers.includes(:prints, prints: :print_jobs).each do |c|
      copies = { one: 0, two: 0 }
      library = 0.0

      c.prints.where(created_at: range).each do |p|
        library += p.article_lines.map { |a_l| a_l.units * a_l.unit_price }.sum

        copies[:one] += p.print_jobs.one_sided.sum(:printed_pages) || 0

        p.print_jobs.two_sided.each do |ts|
          if ts.pages.even?
            copies[:two] += ts.printed_pages
          else
            copies[:one] += ts.copies
            copies[:two] += (ts.pages - 1) * ts.copies
          end
        end
      end

      if copies[:one] > 0 || copies[:two] > 0 || library > 0
        totals[:one_side] += copies[:one]
        totals[:two_sides] += copies[:two]
        totals[:library] += library

        csv << [c.to_s, copies[:one], copies[:two], library]
      end
    end

    csv << [nil, totals[:one_side], totals[:two_sides], totals[:library]] if customers.count > 1
    csv
  end

  def detailed_settlement_as_csv(start = 1.year.ago, finish = Time.zone.now)
    require 'csv'

    double_t  = I18n.t('view.customers_groups.double')
    simple_t  = I18n.t('view.customers_groups.simple')
    library_t = I18n.t('view.customers_groups.library')
    total_t   = I18n.t('view.customers_groups.total')
    comment_t = Print.human_attribute_name(:comment)
    range     = start..finish

    CSV.generate do |csv|
      totals = { simple: 0, double: 0, library: 0.0 }
      csv << []
      csv << [name, simple_t, double_t, library_t, total_t, comment_t]

      customers.each do |c|
        if (prints = c.prints.where(created_at: range)).any?
          csv << []
          csv << [c.to_s]
          customer_totals = { simple: 0, double: 0, library: 0.0 }

          prints.each do |p|
            simple = 0
            double = 0
            p.print_jobs.each do |pj|
              s, d = if pj.two_sided?
                       if pj.pages.even?
                         [0, pj.printed_pages]
                       else
                         [pj.copies, (pj.pages - 1) * pj.copies]
                       end
                     else
                       [pj.printed_pages, 0]
                     end

              simple += s
              double += d
            end

            library = (lines = p.article_lines).any? ? lines.to_a.sum(&:price) : 0.0

            csv << [
              I18n.l(p.created_at, format: :minimal),
              simple,
              double,
              library,
              nil,
              p.comment
            ]

            customer_totals[:simple] += simple
            customer_totals[:double] += double
            customer_totals[:library] += library
            totals[:simple] += simple
            totals[:double] += double
            totals[:library] += library
          end

          csv << [nil, customer_totals[:simple], customer_totals[:double], customer_totals[:library]]
        end
      end

      csv << [nil, totals[:simple], totals[:double], totals[:library]] if customers.count > 1
    end
  end
end
