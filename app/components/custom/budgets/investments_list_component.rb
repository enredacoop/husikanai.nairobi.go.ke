class Budgets::InvestmentsListComponent < ApplicationComponent; end

load Rails.root.join("app", "components", "budgets", "investments_list_component.rb")

class Budgets::InvestmentsListComponent
  # The list of investments is not shown, but the link to see all of them is
  # shown in the same cases as when the list was shown
  def see_all_path
    budget_investments_path(budget)
  end

  def investments?
    case budget.phase
    when "accepting", "reviewing"
      budget.investments.exists?
    when "selecting", "valuating", "publishing_prices"
      budget.investments.feasible.exists?
    when "balloting", "reviewing_ballots"
      budget.investments.selected.exists?
    else
      false
    end
  end
end
