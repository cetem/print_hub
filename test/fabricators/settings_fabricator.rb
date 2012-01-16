Fabricator(:setting) do
  var { %w(price_per_one_sided_copy price_per_two_sided_copy).sample }
  value { '0.10' }
end