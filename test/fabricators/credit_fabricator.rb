Fabricator(:credit) do
  customer
  type { %w(Bonus Deposit).sample }
  amount { (rand * 50.0 + 1.0).round(3) }
  remaining { |c| c.amount }
  valid_until { 1.month.from_now.to_date }
  created_at { 2.days.ago }
  updated_at { 2.days.ago }
end

Fabricator(:bonus, from: :credit) do
  type 'Bonus'
end

Fabricator(:deposit, from: :credit) do
  type 'Deposit'
end