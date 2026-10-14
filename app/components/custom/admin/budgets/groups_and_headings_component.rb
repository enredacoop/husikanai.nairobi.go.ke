class Admin::Budgets::GroupsAndHeadingsComponent < ApplicationComponent; end

load Rails.root.join("app", "components", "admin", "budgets", "groups_and_headings_component.rb")

class Admin::Budgets::GroupsAndHeadingsComponent
  attr_reader :wizard

  # With wizard: true, the links return to the "zones" step of the budgets wizard
  def initialize(budget, wizard: false)
    @budget = budget
    @wizard = wizard
  end

  private

    def wizard_params
      wizard ? { wizard: true } : {}
    end

    def sets
      @sets ||= budget.sets.includes(:translations, groups: [:translations, { headings: :translations }])
                      .sort_by_name
    end

    def groups_without_set
      @groups_without_set ||= budget.groups.where(set: nil).includes(:translations, headings: :translations)
                                    .sort_by(&:name)
    end

    def columns_count
      4 + (budget.show_money? ? 1 : 0) + (budget.approval_voting? ? 1 : 0)
    end

    def empty?
      sets.none? && groups_without_set.none?
    end

    def groups_for(set)
      set.groups.sort_by(&:name)
    end

    def headings_for(group)
      group.headings.sort_by(&:name)
    end

    def headings_count(groups)
      groups.sum { |group| group.headings.size }
    end

    def total_price(groups)
      budget.formatted_amount(groups.sum { |group| group.headings.sum(&:price) })
    end

    def destroy_set_confirmation(name)
      t("admin.budget_sets.destroy.confirm", name: name)
    end
end
