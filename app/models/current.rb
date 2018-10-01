class Current # < ActiveSupport::CurrentAttributes
  # attribute :user, :customer
  # Temporal CurrentAttributes

  def self.user
    ::RequestStore.read('user')
  end

  def self.user=(value)
    ::RequestStore.write('user', value)
  end

  def self.customer
    ::RequestStore.read('customer')
  end

  def self.customer=(value)
    ::RequestStore.write('customer', value)
  end
end
