Fabricator(:order) do
  customer!
  scheduled_at { 1.day.from_now }
  status { Order::STATUS[:pending] }
  print { false }
  notes { Faker::Lorem.sentence }
end