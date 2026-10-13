class Admin::Budgets::ShowComponent < ApplicationComponent; end

load Rails.root.join("app", "components", "admin", "budgets", "show_component.rb")

class Admin::Budgets::ShowComponent
  private

    # The section is folded unless the admin has just changed a borough, subcounty or ward
    def open_groups_and_headings?
      return @open_groups_and_headings if defined?(@open_groups_and_headings)

      @open_groups_and_headings = helpers.session.delete(:open_groups_and_headings).present?
    end
end
