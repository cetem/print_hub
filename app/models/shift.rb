class Shift < ActiveRecord::Base
  has_paper_trail
  
  # Atributos "permitidos"
  attr_accessible :start, :finish, :description, :user_id, :lock_version
  
  # Scopes
  scope :pending, where(finish: nil)
  
  # Restricciones
  validates :start, :user_id, presence: true
  validates_datetime :start, allow_nil: true, allow_blank: true
  validates_datetime :finish, after: :start, allow_nil: true, allow_blank: true
  
  # Relaciones
  belongs_to :user
  
  def initialize(attributes = nil, options = {})
    super(attributes, options)
    
    self.start ||= Time.now
  end
  
  def close!
    self.update_attributes(finish: Time.now)
  end
end