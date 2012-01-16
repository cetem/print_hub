Fabricator(:print) do
  user
  customer
  printer { Cups.show_destinations.select { |p| p =~ /pdf/i }.sample }
  status { Print::STATUS[:paid] }
  revoked { false }
end