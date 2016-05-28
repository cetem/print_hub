class DriveWorker
  require 'gdrive'

  include Sidekiq::Worker

  SHIFTS = 'shifts'

  def perform(task_name, start, finish)
    case task_name
      when SHIFTS
        GDrive.upload_spreadsheat(
          I18n.t(
            'view.shifts.exported_shifts',
            range: [I18n.l(start.to_date), I18n.l(finish.to_date)].join(' => ')
          ),
          Shift.between(start, finish).to_csv
        )
    end
  end
end