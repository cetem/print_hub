# Abaco model
class Upfront < ActiveRecord::Base
  # KIND = [
  #   :upfront,
  #   :to_favor,
  #   :refunded
  # ]

  TransactionKIND = { credit: 0,  debit: 1 }

  establish_connection :"abaco_#{Rails.env}"
  self.table_name = 'movements'

  attr_accessor :auto_operator_name, :operator_id
  default_scope { where(kind: :upfront) }

  belongs_to :user, optional: true
  belongs_to :operator, foreign_key: :to_account_id,
    class_name: 'User',
    primary_key: :abaco_id

  before_validation :assign_operator_attrs
  before_save :set_abaco_defaults

  after_commit :create_abaco_transaction, on: :create

  def initialize(attributes={})
    super(attributes)

    self.kind ||= :upfront
  end

  def assign_operator_attrs
    self.to_account_type = 'Operator'
    self.to_account_id   = User.find_by(id: operator_id)&.abaco_id
  end

  def set_abaco_defaults
    self.charged_by = self.user.to_s
    self.bought_at = Time.zone.now
    self.comment = I18n.t(
      'view.shift_closures.created_by_operator',
      name: self.user
    )
    self.user_id = User.find_by(username: 'abaco').id
  end

  def create_abaco_transaction
    Transaction.create!(
      movement_id: self.id,
      account_id:  self.to_account_id,
      amount:      self.amount,
      kind:        TransactionKIND[:debit]
    )
  end
end
