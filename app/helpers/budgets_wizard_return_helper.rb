# Boroughs, subcounties and wards can be managed from the "zones" step of the
# budgets wizard; the wizard parameter makes their forms return to that step.
module BudgetsWizardReturnHelper
  def wizard_return?
    params[:wizard].present?
  end

  def wizard_return_params
    wizard_return? ? { wizard: true } : {}
  end

  def groups_and_headings_return_path(budget)
    if wizard_return?
      admin_budgets_wizard_budget_groups_path(budget)
    else
      admin_budget_path(budget)
    end
  end
end
