Fabricator(:customer) do
  name { Faker::Name.first_name }
  lastname { [Faker::Name.last_name, sequence(:customer_last_name, 1)].join(' ') }
  identification { sequence(:customer_identification, 1000) }
  email { |p| Faker::Internet.email([p.name, p.lastname].join(' ')) }
  enable { true }
  password { Faker::Lorem.sentence }
  password_confirmation { |p| p.password }
  free_monthly_bonus { 0.0 }
  bonus_without_expiration { false }
end