class Budgets::SetsGroupsAndHeadingsComponent < ApplicationComponent
  attr_reader :budget

  def initialize(budget)
    @budget = budget
  end

  def render?
    budget.sets.any?
  end

  private

    # Each panel is [set, name, groups]; groups without a set go to a last "Other" panel
    def panels
      @panels ||= sets.map { |set| [set, set.name, set.groups.sort_by(&:name)] } + other_panel
    end

    def other_panel
      groups = groups_without_set.sort_by(&:name)
      groups.any? ? [[nil, t("budgets.sets.other"), groups]] : []
    end

    def sets
      budget.sets.includes(:translations, groups: [:translations, { headings: :translations }]).sort_by_name
    end

    def groups_without_set
      budget.groups.where(set: nil).includes(:translations, headings: :translations)
    end

    def panel_id(set)
      set ? dom_id(set, :panel) : "budget_sets_other_panel"
    end

    def button_id(set)
      set ? dom_id(set, :button) : "budget_sets_other_button"
    end

    def summary(groups)
      [
        t("budgets.sets.subcounties", count: groups.size),
        t("budgets.sets.wards", count: groups.sum { |group| group.headings.size })
      ].join(" · ")
    end

    def links_disabled?
      budget.informing? || budget.finished?
    end

    def price(heading)
      tag.span(budget.formatted_heading_price(heading)) if budget.show_money?
    end
end
