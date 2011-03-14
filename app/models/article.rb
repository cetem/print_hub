class Article < ActiveRecord::Base
  # Restricciones
  validates :name, :code, :presence => true
  validates :code, :uniqueness => true, :allow_nil => true, :allow_blank => true
  validates :name, :code, :length => { :maximum => 255 }, :allow_nil => true,
    :allow_blank => true
  validates :price, :presence => true,
    :numericality => { :greater_than_or_equal_to => 0 }

  def to_s
    "[#{self.code}] #{self.name}"
  end
end