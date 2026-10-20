class Budgets::GroupsAndHeadingsComponent < ApplicationComponent; end

load Rails.root.join("app", "components", "budgets", "groups_and_headings_component.rb")

class Budgets::GroupsAndHeadingsComponent
  private

    # Wards link to their investments in every phase but informing, so the
    # projects of finished budgets can be browsed too
    def links_disabled?
      budget.informing?
    end
end
