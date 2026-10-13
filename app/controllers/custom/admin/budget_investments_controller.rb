load Rails.root.join("app", "controllers", "admin", "budget_investments_controller.rb")

class Admin::BudgetInvestmentsController
  private

    alias_method :consul_allowed_params, :allowed_params

    def allowed_params
      project_attributes = [:sector_id, :sub_sector_id, :funding_source, :actual_cost, :start_date, :end_date,
                            :implementing_agency, :contractor]

      [*project_attributes, *consul_allowed_params]
    end
end
