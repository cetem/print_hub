class Upfront < ActiveRecord::Base
  KIND = {
    upfront:  'u',
    to_favor: 'f',
    refunded: 'r',
  }

  establish_connection :"abaco_#{Rails.env}"
  self.table_name = 'outflows'

  attr_accessor :auto_operator_name

  belongs_to :user
  belongs_to :operator, foreign_key: :operator_id, class_name: User

  before_save :set_abaco_defaults

  def initialize(attributes={})
    super(attributes)

    self.kind ||= KIND[:upfront]
  end

  def set_abaco_defaults
    self.bought_at = Time.zone.now
    self.comment = I18n.t(
      'view.shift_closures.created_by_operator',
      name: self.user
    )
  end
end
