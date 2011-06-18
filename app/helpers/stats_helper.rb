module StatsHelper
  def show_stats_total(count)
    distance_of_time = distance_of_time_in_words(@from_date.to_i, @to_date.to_i)
    
    t(:'view.stats.total', :count => count, :distance_time => distance_of_time)
  end
end