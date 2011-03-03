module PaymentsHelper
  def show_paid_with_text(paid_with)
    t :"view.payments.paid_with.#{Payment::PAID_WITH.invert[paid_with]}"
  end
end