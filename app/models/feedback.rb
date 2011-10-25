class Feedback < ApplicationModel
  # Callbacks
  before_destroy :avoid_destruction
  
  # Atributos "solo lectura"
  attr_readonly :positive, :item
  
  # Scopes
  scope :positive, where(positive: true)
  scope :negative, where(positive: false)
  
  def avoid_destruction
    false
  end
end