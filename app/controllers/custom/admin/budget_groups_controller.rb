load Rails.root.join("app", "controllers", "admin", "budget_groups_controller.rb")

class Admin::BudgetGroupsController
  def new
    @group = @budget.groups.new(set: @budget.sets.find_by(id: params[:set_id]))
  end

  private

    # Keeps the boroughs, subcounties and wards section open after changing them
    def groups_index
      session[:open_groups_and_headings] = true unless helpers.wizard_return?
      helpers.groups_and_headings_return_path(@budget)
    end
end
