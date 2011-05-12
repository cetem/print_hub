class AddPendingPaymentToPrint < ActiveRecord::Migration
  def self.up
    add_column :prints, :pending_payment, :boolean, :null => false,
      :default => true

    Print.unscoped.all.each do |p|
      p.update_attribute :pending_payment, p.has_pending_payment?
    end

    add_index :prints, :pending_payment
  end

  def self.down
    remove_index :prints, :column => :pending_payment

    remove_column :prints, :pending_payment
  end
end