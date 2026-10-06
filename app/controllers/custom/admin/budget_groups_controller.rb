load Rails.root.join("app", "controllers", "admin", "budget_groups_controller.rb")

class Admin::BudgetGroupsController
  def new
    @group = @budget.groups.new(set: @budget.sets.find_by(id: params[:set_id]))
  end
end
