class RenameBonusesToCredit < ActiveRecord::Migration
  def up
    remove_foreign_key :bonuses, :column => :customer_id
    
    rename_table :bonuses, :credits
    
    add_column :credits, :type, :string, :null => false, :default => 'Bonus'
    
    add_index :credits, :type
    
    add_foreign_key :credits, :customers, :dependent => :restrict
  end

  def down
    remove_foreign_key :credits, :column => :customer_id
    
    remove_index :credits, :column => :type
    
    remove_column :credits, :type
    
    rename_table :credits, :bonuses
    
    add_foreign_key :bonuses, :customers, :dependent => :restrict
  end
end