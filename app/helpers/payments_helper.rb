module PaymentsHelper
  def show_paid_with_text(paid_with)
    t "view.payments.paid_with.#{Payment::PAID_WITH.invert[paid_with]}"
  end
  
  def show_payments_resume(deposits_amount)
    scope = [:view, :payments]
    resume = [t(:payments_count, :scope => scope, :count => @payments.count)]
    
    if deposits_amount > 0
      resume << "(**) #{t(:deposits_count, :scope => scope, :count => @deposits.count)}"
    end
    
    resume.to_sentence
  end
end