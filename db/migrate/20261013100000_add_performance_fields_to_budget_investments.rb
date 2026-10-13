class AddPerformanceFieldsToBudgetInvestments < ActiveRecord::Migration[7.1]
  def change
    change_table :budget_investments, bulk: true do |t|
      t.string :implementing_agency
      t.string :contractor
    end

    add_column :budget_investment_translations, :performance_indicator, :text
    # Objectives and target are the same field in Nairobi projects
    rename_column :budget_investment_translations, :objectives, :target
  end
end
