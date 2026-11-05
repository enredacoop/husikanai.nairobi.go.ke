class Budgets::Executions::FiltersComponent < ApplicationComponent; end

load Rails.root.join("app", "components", "budgets", "executions", "filters_component.rb")

class Budgets::Executions::FiltersComponent
  private

    def filters_select_counts(status)
      status_counts[status.to_i] || 0
    end

    def status_counts
      @status_counts ||= budget.investments.winners.count_by_latest_milestone_status
    end
end
