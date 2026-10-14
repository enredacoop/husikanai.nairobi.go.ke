class Admin::BudgetsWizard::CreationTimelineComponent < ApplicationComponent; end

load Rails.root.join("app", "components", "admin", "budgets_wizard", "creation_timeline_component.rb")

class Admin::BudgetsWizard::CreationTimelineComponent
  private

    # Boroughs, subcounties and wards are created in a single "zones" step
    def steps
      %w[budget zones phases]
    end

    def current_step
      %w[groups headings].include?(@current_step) ? "zones" : @current_step
    end
end
