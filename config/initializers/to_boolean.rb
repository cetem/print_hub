class Object
  def to_boolean
    ActiveRecord::Type::Boolean.new.cast(self)
  end
end
