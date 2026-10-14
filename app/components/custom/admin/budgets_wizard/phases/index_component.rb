class Admin::BudgetsWizard::Phases::IndexComponent < Admin::BudgetsWizard::BaseComponent; end

load Rails.root.join("app", "components", "admin", "budgets_wizard", "phases", "index_component.rb")

class Admin::BudgetsWizard::Phases::IndexComponent
  private

    def back_link_path
      if single_heading?
        admin_budgets_wizard_budget_group_headings_path(budget, budget.groups.first, url_params)
      else
        admin_budgets_wizard_budget_groups_path(budget)
      end
    end
end
