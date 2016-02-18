class Upfront < ActiveRecord::Base
  #has_paper_trail

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

  def initialize(attributes={})
    super(attributes)

    self.kind ||= KIND[:upfront]
  end
end
