class AddStatusToPrints < ActiveRecord::Migration
  def change
    add_column :prints, :status, :string, limit: 1, null: false,
      default: Print::STATUS[:paid]

    add_index :prints, :status

    Print.unscoped.all.each do |p|
      if p.pending_payment
        p.update_attribute :status, Print::STATUS[:pending_payment]
      end
    end

    remove_column :prints, :pending_payment
  end
end
