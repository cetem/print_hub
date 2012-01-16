Fabricator(:payment) do
  payable(fabricator: :print)
  amount { (rand * 50.0 + 1.0).round(3) }
  paid { |p| p.amount }
  paid_with { Payment::PAID_WITH[:cash] }
  revoked { false }
end