class DriveWorker
  CUSTOMERS_GROUPS = 'customers_groups'
  PAID_SHIFTS = 'paid_shifts'
  SHIFTS = 'shifts'

  include Sidekiq::Worker
  sidekiq_options queue: :low


  def perform(task_name, params)
    case task_name
      when SHIFTS
        start = params['start']
        finish = params['finish']
        ::Gdrive.upload_spreadsheet(
          I18n.t(
            'view.shifts.exported_shifts',
            range: [I18n.l(start.to_date), I18n.l(finish.to_date)].join(' => ')
          ),
          Shift.between(start, finish).to_csv
        )
      when CUSTOMERS_GROUPS
        start = Time.parse(params['start'])
        finish = Time.parse(params['finish'])
        CustomersGroup.upload_settlements(start, finish)
      when PAID_SHIFTS
        start = Time.parse(params['start'])
        finish = Time.parse(params['finish'])

        csv = Shift.where(id: params['ids'].map(&:to_i)).to_csv(
          true,  # detailled
          I18n.t('view.shifts.paid_at', time: I18n.l(Time.zone.now))  # obs
        )

        ::Gdrive.upload_spreadsheet(
          I18n.t(
            'view.shifts.paid_shifts',
            range: [I18n.l(start.to_date), I18n.l(finish.to_date)].join(' => ')
          ),
          csv,
          { label: params['label'] }
        )
    end
  end
end
