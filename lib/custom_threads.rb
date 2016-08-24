module CustomThreads
  def self.wait_for(threads, count = 15)
    wait_statuses = ['run', 'sleep']

    loop do
      begin
        running = threads.map { |t| wait_statuses.include?(t.status) }.count(true)

        break if running < count
      rescue => e
        Bugsnag.notify(e)
        break
      end
      sleep(1)
    end
  end
end
