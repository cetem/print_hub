# Learn more: http://github.com/javan/whenever
#
# Para actualizar la tabla de cron de desarrollo:
# whenever --set environment=development --update-crontab print_hub
# Para eliminarla
# whenever -c print_hub
env :PATH, '"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"'
set :output, Whenever.path + '/log/whenever.log'

every 1.month, at: 'beginning of the month at 00:01' do
  runner 'Customer.create_monthly_bonuses'
end

every 1.day, at: '03:00' do
  rake 'tasks:clean_prints'
end

every 7.days, at: '01:00' do
  rake 'tasks:clean_temp_files'
end

every :sunday, at: '05:00' do
  rake 'tasks:analyze_cups_logs'
end
