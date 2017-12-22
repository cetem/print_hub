module StatsHelper
  def show_stats_total(count)
    distance_of_time = distance_of_time_in_words(@from_date.utc, @to_date.utc)

    t('view.stats.total', count: count, distance_time: distance_of_time)
  end

  def show_stats_total_prints(count)
    distance_of_time = distance_of_time_in_words(@from_date.utc, @to_date.utc)

    t('view.stats.total_prints', count: count, distance_time: distance_of_time)
  end

  def include_stats_js
    content_for(:js_extra) { javascript_include_tag 'graphs' }
  end
end
