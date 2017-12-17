module Prints::Customers

  extend ActiveSupport::Concern

  included do
    attr_readonly :customer_id

    before_create :update_customer_credit, if: -> (p) { p.customer.present? }
    before_validation :assign_surplus_to_customer, if: ->(p) { p.customer.present? }

    validate :need_credit_password?, :pay_later_validations

    belongs_to :customer, autosave: true, optional: true
  end

  def update_customer_credit
    if (credit = payments.detect(&:credit?)) && credit.amount > 0
      avoid_pass_check = order.present? || (
        customer_rfid.present? && customer.rfid == customer_rfid
      )
      remaining = customer.use_credit(
        credit.amount,
        credit_password,
        avoid_password_check: avoid_pass_check
      )

      if remaining == false
        if customer_rfid.present?
          errors.add :base, 'Tarjeta invalida'
        else
          errors.add :credit_password, :invalid
        end

        false
      elsif remaining > 0
        expected_remaining = payments.detect(&:cash?).try(:amount) || 0

        fail 'Invalid payment' if remaining != expected_remaining
      end
    end
  end

  def related_by_customer(type)
    Print.where(customer_id: customer_id).where(
      "#{Print.table_name}.created_at #{type == 'next' ? '>' : '<'} :date",
      date: created_at
    ).order(created_at: :asc).first
  end

  def need_credit_password?
    return if customer_id.blank? || order.present? || persisted? || (customer.free_credit.zero? && !self.pay_later?)

    if customer_rfid.present?
      errors.add(:base, 'Tarjeta invalida') if customer.free_credit > 0 && customer_rfid != customer.rfid
    else
      _error = if credit_password.blank? && customer.free_credit > 0
                   :blank
               elsif credit_password && !customer.valid_password?(credit_password)
                   :invalid
               end

      errors.add(:credit_password, _error) if _error
    end
  end

  def assign_surplus_to_customer
    payments.each do |payment|
      next if payment.destroyed?

      if (diff = payment.paid.to_f - payment.amount.to_f) > 0
        customer.deposits.new(amount: diff)
        payment.paid = payment.amount.to_f
      end
    end
  end

  def pay_later_validations
    return unless self.pay_later?

    self.errors.add :customer_id, :blank if self.customer_id.blank? || self.customer.blank?
    self.errors.add :pay_later, :invalid if self.customer.try(:group_id).blank?
  end
end
