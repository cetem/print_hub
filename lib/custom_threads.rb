module CustomThreads
  def self.wait_for(threads, count = 15)
    wait_statuses = ['run', 'sleep']

    loop do
      begin
        # puts "vueltita..."
        running = threads.map { |t| wait_statuses.include?(t.status) }.count(true)

        # puts running
        # p threads.map { |t| puts t.status }

        break if running < count
      rescue => e
        puts e
        Bugsnag.notify(e)
        break
      end
      sleep(1)
    end
  end
end
