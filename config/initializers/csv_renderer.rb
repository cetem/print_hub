ActionController::Renderers.add :csv do |obj, options|
  filename = options[:filename] || 'data'
  str = obj.respond_to?(:to_csv) ? obj.to_csv : obj.to_s

  send_data(
    str,
    type: "#{Mime[:csv]}; charset=utf-8",
    disposition: "attachment; filename=#{filename}.csv"
  )
end
