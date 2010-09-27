class Print < ActiveRecord::Base
  # Restricciones
  validates :printer, :presence => true
  validates :printer, :length => { :maximum => 255 }, :allow_nil => true,
    :allow_blank => true

  # Relaciones
  belongs_to :user

  def initialize(attributes = nil)
    super(attributes)

    self.user = UserSession.find.try(:user) || self.user rescue self.user
  end
end