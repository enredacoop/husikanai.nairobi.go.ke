class Admin::BudgetInvestments::SearchFormComponent < ApplicationComponent; end

load Rails.root.join("app", "components", "admin", "budget_investments", "search_form_component.rb")

class Admin::BudgetInvestments::SearchFormComponent
  private

    def group_select_options
      budget.groups.sort_by_name.map { |group| [group.name, group.id] }
    end
end
