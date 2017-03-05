class AddCorrelationIdToPaperTrail < ActiveRecord::Migration
  def change
    add_column :versions, :correlation_id, :string

    add_index :versions, :correlation_id
  end
end
