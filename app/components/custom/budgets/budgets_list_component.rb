class Budgets::BudgetsListComponent < ApplicationComponent
  attr_reader :budgets
  use_helpers :can?

  def initialize(budgets)
    @budgets = budgets
  end

  private

    def phase_name(budget)
      budget.current_phase&.name
    end

    def summary(budget)
      text = budget.current_phase&.summary.presence || strip_tags(budget.description.to_s)
      truncate(text.squish, length: 220) if text.present?
    end

    def investments?(budget)
      !budget.informing?
    end

    def results?(budget)
      can?(:read_results, budget)
    end
end
