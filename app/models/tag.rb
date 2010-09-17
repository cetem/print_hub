class Tag < ActiveRecord::Base
  acts_as_tree

  validates :name, :presence => true
  validates :name, :uniqueness => { :scope => :parent_id }, :allow_nil => true,
    :allow_blank => true
  validates :name, :length => { :maximum => 255 }, :allow_nil => true,
    :allow_blank => true
end