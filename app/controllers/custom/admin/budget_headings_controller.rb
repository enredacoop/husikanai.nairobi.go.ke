load Rails.root.join("app", "controllers", "admin", "budget_headings_controller.rb")

class Admin::BudgetHeadingsController
  private

    # Keeps the boroughs, subcounties and wards section open after changing them
    def headings_index
      session[:open_groups_and_headings] = true
      admin_budget_path(@budget)
    end
end
