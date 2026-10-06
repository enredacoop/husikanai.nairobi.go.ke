load Rails.root.join("app", "controllers", "concerns", "admin", "budget_groups_actions.rb")

module Admin::BudgetGroupsActions
  private

    def allowed_params
      valid_attributes = [:max_votable_headings, :set_id]

      [*valid_attributes, translation_params(Budget::Group)]
    end
end
