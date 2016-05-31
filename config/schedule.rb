# Learn more: http://github.com/javan/whenever
#
# Para actualizar la tabla de cron de desarrollo:
# whenever --set environment=development --update-crontab print_hub
# Para eliminarla
# whenever -c print_hub
env :PATH, '"/home/deployer/.gem/ruby/2.1.3/bin:/opt/rubies/ruby-2.1.3/lib/ruby/gems/2.1.0/bin:/opt/rubies/ruby-2.1.3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"'

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

every 1.day, at: '00:01' do
  rake 'tasks:notify_low_stock'
end
