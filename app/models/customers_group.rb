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

  def self.settlement_as_csv
    all.map { |cg| cg.settlement_as_csv }.join("\n\n")
  end

  def settlement_as_csv
    require 'csv'

    double_t          = I18n.t('view.customers_groups.double')
    simple_t          = I18n.t('view.customers_groups.simple')
    total_t           = I18n.t('view.customers_groups.total')
    subtotal_copies_t = I18n.t('view.customers_groups.subtotal_copies')
    global_simple     = 0
    global_double      = 0

    CSV.generate do |csv|

      csv << [nil, self.name]
      csv << []

      customers.each do |c|
        if (pay_later = c.print_jobs.pay_later).count > 0
          total_simple = 0
          total_double = 0

          csv << [
            self.name,
            I18n.t('view.customers_groups.date'),
            simple_t,
            I18n.t('view.customers_groups.copies'),
            I18n.t('view.customers_groups.pages'),
            total_t,
            double_t,
            I18n.t('view.customers_groups.copies'),
            I18n.t('view.customers_groups.pages'),
            total_t
          ]

          pay_later.order(:created_at).each do |pj|
            new_row = [
              "#{c.name} #{c.lastname}",
              I18n.l(pj.created_at.to_date)
            ]

            new_row << if pj.two_sided
                         if (pj.pages % 2).zero?
                           total = pj.copies * pj.pages
                           total_double += total
                           global_double += total

                           [
                             '', '', '', '',
                             double_t, pj.copies, pj.pages, pj.copies * pj.pages
                           ]
                         else
                           total = pj.copies * (pj.pages - 1)
                           total_double += total
                           total_simple += pj.copies
                           global_double += total
                           global_simple += pj.copies

                           [
                             simple_t, pj.copies, 1, pj.copies,
                             double_t, pj.copies, pj.pages - 1, total
                           ]
                         end
                       else
                         total = pj.copies * pj.pages
                         total_simple += total
                         global_simple += total

                         [simple_t, pj.copies, pj.pages, total]
                       end

            csv << new_row.flatten
          end

          csv << [
            '','',
            subtotal_copies_t, '',
            total_simple, '',
            subtotal_copies_t, '',
            total_double, ''
          ]

          csv << []
          csv << ['', '', total_t]
          csv << []
          csv << []
        end
      end
      csv << ['', simple_t, global_simple, '', double_t, global_double]
    end
  end
end
