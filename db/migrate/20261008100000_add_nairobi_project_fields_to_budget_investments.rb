class AddNairobiProjectFieldsToBudgetInvestments < ActiveRecord::Migration[7.1]
  def change
    create_table :sectors do |t|
      t.string :name, null: false
      t.references :parent, foreign_key: { to_table: :sectors }, index: true

      t.timestamps
    end
    add_index :sectors, [:parent_id, :name], unique: true

    change_table :budget_investments, bulk: true do |t|
      t.bigint :actual_cost
      t.date :start_date
      t.date :end_date
      t.string :funding_source
      t.references :sector, foreign_key: true, index: true
      t.references :sub_sector, foreign_key: { to_table: :sectors }, index: true
    end

    add_column :budget_investment_translations, :objectives, :text
  end
end
