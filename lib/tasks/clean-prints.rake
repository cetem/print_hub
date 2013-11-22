namespace :tasks do
  desc 'Cleaning not completed prints'
  task :clean_prints do
    jobs = `lpstat -Wnot-completed -o | awk '{print $1}'`

    jobs.split("\n").each do |j|
      id = j.match(/(\d+)$/)[1]
      if system("lprm #{id}")
        `echo "#{id} cancelled" >> log/cancelled_prints.log`
      end
    end
  end
end
