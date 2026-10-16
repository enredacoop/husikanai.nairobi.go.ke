class Budgets::InvestmentsListComponent < ApplicationComponent; end

load Rails.root.join("app", "components", "budgets", "investments_list_component.rb")

class Budgets::InvestmentsListComponent
  # The list of investments is not shown, but the link to see all of them is
  # shown in every phase but informing, even when there are no investments yet
  def see_all_path
    budget_investments_path(budget)
  end
end
