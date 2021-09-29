# Learn more: http://github.com/javan/whenever
#
# Para actualizar la tabla de cron de desarrollo:
# whenever --set environment=development --update-crontab print_hub
# Para eliminarla
# whenever -c print_hub
# env :PATH, '"/home/deployer/.gem/ruby/2.4.3/bin:/opt/rubies/ruby-2.4.3/lib/ruby/gems/2.4.0/bin:/opt/rubies/ruby-2.4.3/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games"'
env :SHELL, '/bin/bash'

chruby_version = '2.6.6'
chruby_bin = '/usr/local/bin/chruby-exec'
chruby_cmd = "#{chruby_bin} #{chruby_version} --"

set :job_template, nil
set :output, 'log/whenever.log'
job_type :command, ':task :output'
job_type :rake,    "cd :path && #{chruby_cmd} :environment_variable=:environment bundle exec rake :task :output"
job_type :runner,  "cd :path && #{chruby_cmd} bin/rails runner -e :environment ':task' :output"
job_type :script,  "cd :path && #{chruby_cmd} :environment_variable=:environment bundle exec script/:task :output"

every :month, at: 'beginning of the month at 04:01' do
  runner 'Customer.create_monthly_bonuses'
end

every :month, at: 'beginning of the month at 06:01' do
  rake 'tasks:export_shift_closures'
end

every 1.day, at: '05:00' do
  rake 'tasks:clean_prints'
end

every 7.days, at: '01:00' do
  rake 'tasks:clean_temp_files'
  rake 'tasks:clean_orders'
end

every :sunday, at: '05:00' do
  rake 'tasks:analyze_cups_logs'
end

# every 1.day, at: '23:31' do
#   rake 'tasks:notify_low_stock'
# end

# every 1.day, at: '23:01' do
#   rake 'tasks:shifts_cop'
# end
