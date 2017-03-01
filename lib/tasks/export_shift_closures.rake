require 'gdrive'
namespace :tasks do
  desc 'Export shift closures to gdrive'
  task export_shift_closures: :environment do |_task, args|
    date = if (date_to_export = ENV['date_to_export'])
             Time.zone.parse(date_to_export)
           else
             1.month.ago
           end
    start_date = date.beginning_of_month
    finish_date = date.end_of_month
    GDrive.upload_spreadsheet(
      I18n.t('view.shift_closures.dailies_for_year', year: date.year),
      ShiftClosure.between(start_date, finish_date).to_csv,
      { month: date.month }
    )
  end
end
