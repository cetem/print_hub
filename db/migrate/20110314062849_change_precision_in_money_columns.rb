class ChangePrecisionInMoneyColumns < ActiveRecord::Migration
  def self.up
    change_column :customers, :free_monthly_bonus, :decimal,
                  precision: 15, scale: 3
    change_column :print_jobs, :price_per_copy, :decimal, null: false,
                                                          precision: 15, scale: 3
    change_column :payments, :amount, :decimal, null: false,
                                                precision: 15, scale: 3
    change_column :payments, :paid, :decimal, null: false,
                                              precision: 15, scale: 3
    change_column :bonuses, :amount, :decimal, null: false,
                                               precision: 15, scale: 3
    change_column :bonuses, :remaining, :decimal, null: false,
                                                  precision: 15, scale: 3
  end

  def self.down
    change_column :customers, :free_monthly_bonus, :decimal,
                  precision: 15, scale: 2
    change_column :print_jobs, :price_per_copy, :decimal, null: false,
                                                          precision: 15, scale: 2
    change_column :payments, :amount, :decimal, null: false,
                                                precision: 15, scale: 2
    change_column :payments, :paid, :decimal, null: false,
                                              precision: 15, scale: 2
    change_column :bonuses, :amount, :decimal, null: false,
                                               precision: 15, scale: 2
    change_column :bonuses, :remaining, :decimal, null: false,
                                                  precision: 15, scale: 2
  end
end
