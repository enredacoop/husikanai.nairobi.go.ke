load Rails.root.join("app", "controllers", "budgets_controller.rb")

class BudgetsController
  skip_before_action :load_current_budget, only: :index

  # Lists every budget instead of showing the current one
  def index
    @budgets = @budgets.order(created_at: :desc, id: :desc).select { |budget| budget_published?(budget) }
  end
end
