class CreateBudgetSets < ActiveRecord::Migration[7.1]
  def change
    create_table :budget_sets do |t|
      t.references :budget, foreign_key: true, index: true
      t.string :slug

      t.timestamps
    end

    create_table :budget_set_translations do |t|
      t.references :budget_set, null: false, foreign_key: true, index: true
      t.string :locale, null: false
      t.string :name

      t.timestamps
    end
    add_index :budget_set_translations, :locale

    add_reference :budget_groups, :set, foreign_key: { to_table: :budget_sets }, index: true
  end
end
