# Table rows of a group (subcounty) and its headings (wards) in the admin budget page
class Admin::Budgets::GroupRowsComponent < ApplicationComponent
  attr_reader :group, :headings, :nested

  def initialize(group, headings, nested:)
    @group = group
    @headings = headings
    @nested = nested
  end

  private

    def budget
      group.budget
    end

    def level_class(level)
      "level-#{level + (nested ? 1 : 0)}"
    end

    def columns_count
      4 + (budget.show_money? ? 1 : 0) + (budget.approval_voting? ? 1 : 0)
    end

    def total_price
      budget.formatted_amount(headings.sum(&:price))
    end

    def geozone_for(heading)
      if heading.geozone
        link_to heading.geozone.name, edit_admin_geozone_path(heading.geozone)
      else
        t("geozones.none")
      end
    end
end
