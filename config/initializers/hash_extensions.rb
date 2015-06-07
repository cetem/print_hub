class Hash
  autoload :CSV, 'csv'

  def to_csv
    CSV.generate { |csv| each { |k, v| csv << [k.to_s, v.to_s] } }
  end
end
