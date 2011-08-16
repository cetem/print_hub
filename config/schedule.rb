# Learn more: http://github.com/javan/whenever
#
# Para actualizar la tabla de cron de desarrollo:
# whenever --set environment=development --update-crontab print_hub
# Para eliminarla
# whenever -c print_hub
env :PATH, '"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"'

every 1.month, :at => 'beginning of the month at 00:01' do
  runner 'Customer.create_monthly_bonuses'
end

every 1.day, :at => '00:01' do
  runner 'Customer.destroy_inactive_accounts'
end