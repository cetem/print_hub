module Prints::Customers

  extend ActiveSupport::Concern

  included do
    attr_readonly :customer_id

    before_create :update_customer_credit, if: -> (p) { p.customer.present? }
    before_validation :assign_surplus_to_customer, if: ->(p) { p.customer.present? }

    validates_each :customer_id do |record, attr, value|
      record.errors.add attr, :blank if value.blank? && record.pay_later?
    end

    validate :need_credit_password?

    belongs_to :customer, autosave: true
  end

  def update_customer_credit
    if (credit = payments.detect(&:credit?)) && credit.amount > 0
      remaining = customer.use_credit(
        credit.amount,
        credit_password,
        avoid_password_check: order.present?
      )

      if remaining == false
        errors.add :credit_password, :invalid

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
    return unless customer_id
    return if order.present? || persisted?

    _error = if credit_password.blank? && customer.free_credit > 0
                 :blank
             elsif credit_password && !customer.valid_password?(credit_password)
                 :invalid
             end

    errors.add(:credit_password, _error) if _error
  end

  def assign_surplus_to_customer
    payments.each do |payment|
      return if payment.destroyed?

      if (diff = payment.paid.to_f - payment.amount.to_f) > 0
        customer.deposits.new(amount: diff)
        payment.paid = payment.amount.to_f
      end
    end
  end
end
