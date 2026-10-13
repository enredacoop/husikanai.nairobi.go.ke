class Admin::BudgetsWizard::Groups::IndexComponent < Admin::BudgetsWizard::BaseComponent; end

load Rails.root.join("app", "components", "admin", "budgets_wizard", "groups", "index_component.rb")

class Admin::BudgetsWizard::Groups::IndexComponent
  attr_reader :importer

  def initialize(groups, new_group, importer: nil)
    @groups = groups
    @new_group = new_group
    @importer = importer
  end
end
