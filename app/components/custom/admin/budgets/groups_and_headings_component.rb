class Admin::Budgets::GroupsAndHeadingsComponent < ApplicationComponent; end

load Rails.root.join("app", "components", "admin", "budgets", "groups_and_headings_component.rb")

class Admin::Budgets::GroupsAndHeadingsComponent
  private

    def sets
      budget.sets.sort_by_name
    end

    def groups_without_set
      budget.groups.where(set: nil)
    end

    def destroy_set_confirmation(name)
      t("admin.budget_sets.destroy.confirm", name: name)
    end
end
