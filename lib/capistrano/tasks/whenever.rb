# namespace :deploy do
  # after :updated,  'whenever:update_crontab'

  # namespace :whenever do
  #   task :update_crontab do
  #     on roles(:app) do
  #       within current_path do
  #         execute :bundle, :exec, :whenever, "--update-crontab #{fetch(:application)}"
  #       end
  #     end
  #   end
  # end
# end
